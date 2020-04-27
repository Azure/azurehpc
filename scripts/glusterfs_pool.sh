#/bin/bash

GLUSTERFSNODE0=$1

systemctl glusterd start
systemctl glusterd status

gluster peer probe $GLUSTERFSNODE0
