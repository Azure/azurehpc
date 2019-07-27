#!/bin/bash
#
# This script does not require any parameters.
#
get_ib_pkey()
{
 key0=$(cat /sys/class/infiniband/mlx5_0/ports/1/pkeys/0)
 key1=$(cat /sys/class/infiniband/mlx5_0/ports/1/pkeys/1)
 
 if [ $(($key0 - $key1)) -gt 0 ]; then
 echo $key0
 else
 echo $key1
 fi
}

get_ib_pkey
