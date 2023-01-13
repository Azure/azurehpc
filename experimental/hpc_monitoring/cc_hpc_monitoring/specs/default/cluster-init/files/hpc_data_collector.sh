#!/bin/bash

LOG_EVENT_NAME="MyHPCMonitor"
DCGMI_FIELDS="203,252,1004"
TIME_INTERVAL_SECS=10

SCRIPT_DIR=/opt/hpc_monitoring

source /etc/profile.d/hpc_monitoring.sh


${SCRIPT_DIR}/hpc_data_collector.py \
                                    -nle $LOG_EVENT_NAME \
                                    -fhm \
                                    -gpum \
                                    -dfi $DCGMI_FIELDS \
                                    -cpum \
                                    -cpu_memm \
                                    -nfsm \
                                    -ethm \
                                    -ibm \
                                    -tis $TIME_INTERVAL_SECS
