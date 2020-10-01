#!/bin/bash
# Create a cluster.json file in the root of /data and push it to log analytics
# Pre-requisits :
#   - /data must exists => nfsclient.sh or nfsserver.sh must be executed before on the machine running this script
#   - Log Anaytics must be configured => analytics.sh must be executed before on the machine running this script
set -e
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cluster_id=$1
resource_group=$2
environment=$3
scheduler=$4

AZHPC_DATAROOT=/data

createOn=$(date -u)
cat <<EOF >$AZHPC_DATAROOT/cluster.json
{
    "clusterId": "$cluster_id",
    "resource_group": "$resource_group",
    "createdOn": "$createOn",
    "environment": "$environment",
    "scheduler": "$scheduler"
}
EOF

$DIR/send_to_loganalytics.sh "cluster" $AZHPC_DATAROOT/cluster.json
