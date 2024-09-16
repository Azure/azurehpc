#!/bin/bash

yum -y install lustre kmod-lustre-osd-ldiskfs lustre-osd-ldiskfs-mount lustre-resource-agents e2fsprogs || exit 1

sed -i 's/ResourceDisk\.Format=y/ResourceDisk.Format=n/g' /etc/waagent.conf

systemctl restart waagent

weak-modules --add-kernel --no-initramfs

umount /mnt/resource
