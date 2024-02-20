#!/bin/bash

HOSTLIST=hostlist
INTERVAL_MINS=1
SCRIPT_PATH=~
EXE_PATH="${SCRIPT_PATH}/hpc_data_collector.py -uc \>\> /tmp/hpc_data_collector.log"
PDSH_RCMD_TYPE=ssh


WCOLL=$HOSTLIST pdsh "if ! [ -f /etc/crontab.orig ]; then sudo cp /etc/crontab /etc/crontab.orig; echo "\*/$INTERVAL_MINS \\* \\* \\* \\* root $EXE_PATH" 2>&1 | sudo tee -a /etc/crontab;fi"
