#!/bin/bash
LSF_DIR=/apps/lsf

source $LSF_DIR/conf/profile.lsf 
cd $LSF_DIR/10.1/install
sudo ./hostsetup --top="$LSF_DIR" --boot="y" --dynamic --start="y"

ps -aux | grep lsf

