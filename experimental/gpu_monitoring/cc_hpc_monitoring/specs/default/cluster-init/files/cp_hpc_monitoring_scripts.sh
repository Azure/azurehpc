#!/bin/bash

FILES="hpc_data_collector.py hpc_data_collector.sh"
DEST_DIR=/opt/hpc_monitoring

mkdir $DEST_DIR

for file in $FILES
do
   cp $CYCLECLOUD_SPEC_PATH/files/$file $DEST_DIR
   chmod 755 $DEST_DIR/$file
done
