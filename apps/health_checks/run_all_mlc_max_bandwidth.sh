#!/bin/bash

HOSTFILE_PATH=$1
SCRIPT_DIR=${2:-.}

OUTDIR=`date +%Y%m%d_%H%M%S`
if [ ! -d $OUTDIR ]; then
   mkdir $OUTDIR
fi

sudo yum install -y pdsh

HOSTNAME=`hostname`

cd $OUTDIR
WCOLL=$HOSTFILE_PATH pdsh -f 64 ${SCRIPT_DIR}/mlc --max_bandwidth >& ${HOSTNAME}.out 

grep Stream-triad *.out | sort -n -k 3 2>&1 | tee mlc_stream_report.out
