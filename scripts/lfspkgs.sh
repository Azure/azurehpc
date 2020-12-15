#!/bin/bash

# Use CentOS repo to install resource-agents (RHEL does not install them by default)
if  grep -qF "Red Hat" /etc/redhat-release ; then
    cat << EOF >> /etc/yum.repos.d/centos.repo
[centos-7-base]
name=CentOS-7 - Base
mirrorlist=http://mirrorlist.centos.org/?release=7&arch=\$basearch&repo=os
#baseurl='http://mirror.centos.org/centos/7/os/\$basearch/'
enabled=1
gpgcheck=1
gpgkey=http://ftp.heanet.ie/pub/centos/7/os/x86_64/RPM-GPG-KEY-CentOS-7
EOF
    # Stop and disable the firewall for lnet to work
    systemctl stop firewalld.service
    systemctl disable firewalld.service
fi

yum -y install resource-agents dkms lustre kmod-lustre-osd-ldiskfs lustre-osd-ldiskfs-mount lustre-resource-agents e2fsprogs lustre-tests || exit 1

sed -i 's/ResourceDisk\.Format=y/ResourceDisk.Format=n/g' /etc/waagent.conf

systemctl restart waagent

weak-modules --add-kernel --no-initramfs

if [ -f "/etc/systemd/system/temp-disk-swapfile.service" ]; then
    systemctl stop temp-disk-swapfile.service
fi

if [ -d /mnt/resource ]; then
    umount /mnt/resource
fi
