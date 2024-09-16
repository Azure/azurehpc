#!/bin/bash
yum -y --nogpgcheck --enablerepo=lustreserver install kmod-lustre kmod-lustre-osd-ldiskfs lustre-osd-ldiskfs-mount lustre lustre-resource-agents
modprobe -v lustre

sed -i 's/ResourceDisk\.Format=y/ResourceDisk.Format=n/g' /etc/waagent.conf
sed -i 's/# OS.EnableRDMA=y/OS.EnableRDMA=y/g' /etc/waagent.conf  

weak-modules --add-kernel --no-initramfs
systemctl enable lustre
umount /mnt/resource
