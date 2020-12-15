#!/bin/bash

HOSTFILE_PATH=$1
SCRIPT_DIR=${2:-`pwd`}

OUTDIR=`pwd`/`date +%Y%m%d_%H%M%S`
if [ ! -d $OUTDIR ]; then
   mkdir $OUTDIR
fi

sudo yum install -y pdsh

HOSTNAME=`hostname`

cd $OUTDIR
WCOLL=$HOSTFILE_PATH pdsh -f 64 ${SCRIPT_DIR}/run_mlc_max_bandwidth.sh --max_bandwidth $OUTDIR

grep Stream-triad *.out | sort -n -k 3 2>&1 | tee mlc_stream_report.out
