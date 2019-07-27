#!/bin/bash
#
# This script requires a single parameter
# first parameter : Full path to output directory.
#
OUTPUT_DIR=$1
sudo yum install -y numactl 
HOSTNAME=`hostname`
mkdir -p $OUTPUT_DIR/$HOSTNAME
cd $OUTPUT_DIR/$HOSTNAME
echo `hostname` >& hostname.out
ib_write_bw -b >& /dev/null &
sleep 5
ib_write_bw -b -D 10 $HOSTNAME >& ib_write_bw.out_$$
