#!/bin/bash

# arg: $1 = lfsserver
master=$1

yum install -y https://downloads.whamcloud.com/public/lustre/lustre-2.10.6/el7/client/RPMS/x86_64/kmod-lustre-client-2.10.6-1.el7.x86_64.rpm
yum install -y https://downloads.whamcloud.com/public/lustre/lustre-2.10.6/el7/client/RPMS/x86_64/lustre-client-2.10.6-1.el7.x86_64.rpm
weak-modules --add-kernel $(uname -r)

mkdir /lustre
#mount -t lustre ${master}@tcp0:/LustreFS /lustre
echo "${master}@tcp0:/LustreFS /lustre lustre defaults,_netdev 0 0" >> /etc/fstab
mount -a
chmod 777 /lustre
