#!/bin/bash
#
# This script requires three parameters.
# first paramater : Full path to intel bin directory containing the script compilervars.sh
# second parameter : Full path to the stream executable.
# third paramater : Full path to the output directory.

INTELBIN_DIR=$1
EXEPATH=$2
OUTPUT_DIR=$3
source ${INTELBIN_DIR}/compilervars.sh intel64
#
sudo yum install -y numactl 
HOSTNAME=`hostname`
mkdir -p $OUTPUT_DIR/$HOSTNAME
cd $OUTPUT_DIR/$HOSTNAME
$EXEPATH >& stream.out_$$
