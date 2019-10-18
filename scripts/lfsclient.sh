#!/bin/bash

# arg: $1 = lfsserver
master=$1

cat << EOF >/etc/yum.repos.d/LustrePack.repo
[lustreclient]
name=lustreclient
baseurl=https://downloads.whamcloud.com/public/lustre/latest-2.10-release/el7/client/
enabled=1
gpgcheck=0
EOF

yum install -y kmod-lustre-client lustre-client
weak-modules --add-kernel $(uname -r)

mkdir /lustre
echo "${master}@tcp0:/LustreFS /lustre lustre defaults,_netdev 0 0" >> /etc/fstab
mount -a
chmod 777 /lustre
