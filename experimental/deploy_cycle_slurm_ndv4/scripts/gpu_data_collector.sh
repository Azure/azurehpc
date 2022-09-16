#!/bin/bash

DCGMI_FIELDS="203,252,1004"
LOG_EVENT_NAME="MyGPUMonitor"
TIME_INTERVAL_SECS=10

SCRIPT_DIR=/opt/gpu_monitoring

source /etc/profile.d/gpu_monitoring.sh


${SCRIPT_DIR}/gpu_data_collector.py \
                                    -dfi $DCGMI_FIELDS \
                                    -nle $LOG_EVENT_NAME \
                                    -ibm \
                                    -tis $TIME_INTERVAL_SECS
