#!/bin/bash
yum install -y nfs-utils

mkdir -p /netapps
echo "10.2.8.4:/raymondanfvol /netapps nfs bg,rw,hard,noatime,nolock,rsize=65536,wsize=65536,vers=3,tcp,_netdev 0 0" >>/etc/fstab

mount -a

chmod 777 /netapps
