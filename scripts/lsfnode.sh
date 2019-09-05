#!/bin/bash

LSF_TOP=/apps/lsf
CLUSTERNAME=azhpc

source $LSF_TOP/conf/profile.lsf 
cd $LSF_TOP/10.1/install
sudo ./hostsetup --top="$LSF_TOP" --boot="y" --dynamic --start="y"

ps -aux | grep lsf

