#!/bin/bash
# jump the gun here to ensure passwordless ssh as root between all lustre nodes to faciltate node reboot
cp -r /share/home/hpcuser/.ssh ~/

yum -y --nogpgcheck --disablerepo=* --enablerepo=e2fs install e2fsprogs

yum -y --nogpgcheck --disablerepo=base,extras,updates --enablerepo=lustreserver install kernel kernel-devel kernel-headers kernel-tools kernel-tools-libs 2>/dev/null

