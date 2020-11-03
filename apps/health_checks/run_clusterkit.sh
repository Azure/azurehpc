#!/bin/bash

HOSTLIST_PATH=$1

module load mpi/hpcx

python clusterkit.sh -f $HOSTLIST
