#/bin/bash

HOSTLIST=$1

systemctl glusterd start
systemctl glusterd status

if [ "$PSSH_NODENUM" = "0" ]; then
   for host in `cat hostlists/$HOSTLIST`
   do 
      gluster peer probe $host
   done
fi
