#!/bin/bash

HOSTLIST_PATH=$1

module load mpi/hpcx

clusterkit.sh -f $HOSTLIST_PATH
