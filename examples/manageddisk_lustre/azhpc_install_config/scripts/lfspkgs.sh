#!/bin/bash

cat << EOF >/etc/yum.repos.d/LustrePack.repo
[lustreserver]
name=lustreserver
baseurl=https://downloads.whamcloud.com/public/lustre/latest-2.10-release/el7.6.1810/server/
enabled=1
gpgcheck=0

[e2fs]
name=e2fs
baseurl=https://downloads.whamcloud.com/public/e2fsprogs/latest/el7/
enabled=1
gpgcheck=0

[lustreclient]
name=lustreclient
baseurl=https://downloads.whamcloud.com/public/lustre/latest-2.10-release/el7.6.1810/client/
enabled=1
gpgcheck=0
EOF

yum -y install kernel-3.10.0-957.el7_lustre.x86_64 lustre kmod-lustre kmod-lustre-osd-ldiskfs lustre-osd-ldiskfs-mount e2fsprogs lustre-tests

sed -i 's/ResourceDisk\.Format=y/ResourceDisk.Format=n/g' /etc/waagent.conf
