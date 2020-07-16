#/bin/bash

HOSTLIST=$1

systemctl start glusterd
systemctl status glusterd

for host in $HOSTLIST
do 
	gluster peer probe $host
done
