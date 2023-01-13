#!/bin/bash

log_analytcs_ws_customer_id=$1
log_analytcs_ws_key=$2

ENV_FILE=/etc/profile.d/hpc_monitoring.sh

cat <<EOF >$ENV_FILE
export LOG_ANALYTICS_CUSTOMER_ID="$log_analytcs_ws_customer_id"
export LOG_ANALYTICS_SHARED_KEY="$log_analytcs_ws_key"
EOF

chmod 700 $ENV_FILE
