#!/bin/bash

OUTDIR=$1

module use /apps/modulefiles
module load mlc

HOSTNAME=`hostname`

cd $OUTDIR
mlc --max_bandwidth >& ${HOSTNAME}.out
