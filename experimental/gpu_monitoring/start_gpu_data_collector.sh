#!/bin/bash

HOSTLIST=hostlist
INTERVAL_SECS=30
DCGM_FIELD_IDS="203,252,1004"
SCRIPT_PATH=~
EXE_PATH="${SCRIPT_PATH}/gpu_data_collector.py -tis $INTERVAL_SECS -dfi $DCGM_FIELD_IDS \>\> /tmp/gpu_data_collector.log"
PDSH_RCMD_TYPE=ssh


WCOLL=$HOSTLIST pdsh sudo $EXE_PATH
