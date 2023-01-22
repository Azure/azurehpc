#!/bin/bash

HOSTLIST=hostlist
export PDSH_RCMD_TYPE=ssh


WCOLL=$HOSTLIST pdsh "sudo pkill -f hpc_data_collector.py"
