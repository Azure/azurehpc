#/bin/bash

GLUSTERFSNODE0=$1
gluster peer probe $GLUSTERFSNODE0
