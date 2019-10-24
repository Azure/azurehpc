#!/bin/bash

# arg: $1 = lfsserver
master=$1

yum install -y kmod-lustre-client lustre-client
weak-modules --add-kernel $(uname -r)

mkdir /lustre
echo "${master}@tcp0:/LustreFS /lustre lustre defaults,_netdev 0 0" >> /etc/fstab
mount -a
chmod 777 /lustre
