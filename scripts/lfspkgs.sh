#!/bin/bash

cat << EOF >/etc/yum.repos.d/LustrePack.repo
[lustreserver]
name=lustreserver
baseurl=https://downloads.whamcloud.com/public/lustre/latest-2.10-release/el7/patchless-ldiskfs-server/
enabled=1
gpgcheck=0

[e2fs]
name=e2fs
baseurl=https://downloads.whamcloud.com/public/e2fsprogs/latest/el7/
enabled=1
gpgcheck=0

[lustreclient]
name=lustreclient
baseurl=https://downloads.whamcloud.com/public/lustre/latest-2.10-release/el7/client/
enabled=1
gpgcheck=0
EOF

yum -y install lustre kmod-lustre-osd-ldiskfs lustre-osd-ldiskfs-mount lustre-resource-agents e2fsprogs lustre-tests

sed -i 's/ResourceDisk\.Format=y/ResourceDisk.Format=n/g' /etc/waagent.conf

systemctl restart waagent

weak-modules --add-kernel --no-initramfs

umount /mnt/resource
