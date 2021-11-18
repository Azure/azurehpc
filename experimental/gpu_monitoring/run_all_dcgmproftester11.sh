#!/bin/bash

HOSTLIST=hostlist
PDSW_RCMD_TYPE=ssh
SCRIPT_PATH=~

WCOLL=$HOSTLIST pdsh ${SCRIPT_PATH}/run_dcgmproftester11.sh
