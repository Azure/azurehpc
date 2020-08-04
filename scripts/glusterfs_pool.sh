#/bin/bash

HOSTLIST=$1

systemctl start glusterd
systemctl status glusterd

if [ -n "$HOSTLIST" ]; then
   if [ "$PSSH_NODENUM" = "0" ]; then
      for host in $HOSTLIST
      do 
         gluster peer probe $host
      done
   fi
fi