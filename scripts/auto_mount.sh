#!/bin/bash
yum install -y nfs-utils

 

anfmountpath = $1
anfmountpoint = $2
filesystem = "nfs"

 

mkdir -p $anfmountpoint

 


echo "$anfmountpath $anfmountpoint $filesystem bg,rw,hard,noatime,nolock,rsize=65536,wsize=65536,vers=3,tcp,_netdev 0 0" >>/etc/fstab

 

mount -a

 

chmod 777 $anfmountpoint
