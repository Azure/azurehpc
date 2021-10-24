#!/bin/bash

HOSTLIST=/shared/home/cycleadmin/healthchecks/hostlist
SCRIPT_BASE_DIR=/shared/home/cycleadmin/healthchecks

WCOLL=$HOSTLIST pdsh ${SCRIPT_BASE_DIR}/IB/run_ib_write_bw_GDR.sh
WCOLL=$HOSTLIST pdsh ${SCRIPT_BASE_DIR}/bandwidthtest/run_bandwidthtest.sh
WCOLL=$HOSTLIST pdsh ${SCRIPT_BASE_DIR}/misc_gpu/run_misc_gpu.sh
WCOLL=$HOSTLIST pdsh ${SCRIPT_BASE_DIR}/misc_ib/run_misc_ib.sh
