#!/bin/bash
# Pre-requisits : 
#   - Log Anaytics must be configured => analytics.sh must be executed before on the machine running this script
source /etc/bashrc
set -o pipefail
mds_api_version="2018-10-01"
echo "Command to launch: $@"
T0=$SECONDS

# Build working directory
WORKING_DIR=/data/$PBS_QUEUE/$PBS_JOBID
mkdir -p $WORKING_DIR
pushd $WORKING_DIR
export AZHPC_JOBDIR=$WORKING_DIR 

$@
return_code=$?
if [ "$return_code" != "0" ]; then
    app_status="failed"
else
    app_status="success"
fi

CORES=$(cat $PBS_NODEFILE | wc -l)
PPN=$(cat $PBS_NODEFILE | uniq -c | head -1 | awk '{ print $1 }')
NODES=$(sort -u < $PBS_NODEFILE | wc -l)
NODELIST=$(sort -u < $PBS_NODEFILE | tr '\n' ' ')
# Remove domain .internal.cloudapp.net names
NODELIST=$(echo $NODELIST | sed 's/.internal.cloudapp.net//g')
NODELIST=$(echo ${NODELIST%%*( )})

elapsed_time=$(($SECONDS - ${T0-$SECONDS}))

# If an application parser script exists, call it
app_data="{}"
SCRIPT_DIR=$( dirname "$1" )
SCRIPT_NAME=$( basename "${1%.*}" )
PARSER=$SCRIPT_DIR/parser_$SCRIPT_NAME.sh
if [ -s $PARSER ]; then
    echo "calling $PARSER"
    set +e
    shift
    source $PARSER $@
    parser_exit=$?
    set -e
    if [ "$parser_exit" = "0" ]; then
        # We need to merge app.json with generic telemetry data
        app_data=$(cat app.json)
    fi
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Retrieve the cluster Id
RUN_ID="$(uuidgen | tr -d '\n-' | tr '[:upper:]' '[:lower:]')"
cluster_id=$(jq -r '.clusterId' /data/cluster.json)

# build the poolId
vmssName=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=$mds_api_version" | jq -r '.compute.vmScaleSetName')
poolId=$cluster_id$vmssName

# retrieve the storage filesystem used if any and add the storage Id
filesystem=$(jq -r '.filesystem' <<< $app_data)
if [ "$filesystem" != "null" ]; then
    storage_id=$(jq -r '.storageId' $filesystem/storage.json)
fi
app_name=$(jq -r '.app' <<< $app_data)
# Create the application benchmark record
jq -n '.clusterId=$clusterid | .poolId=$poolId | .storageId=$storageId | .vmssName=$vmssName | .runId=$runid | .nodes=$nodes | .cores=$cores | .ppn=$ppn | .nodelist=$nodelist | .status=$status | .elapsed_time=$elapsed | . += $app' \
    --argjson app "$app_data" \
    --arg clusterid "$cluster_id" \
    --arg poolId "$poolId" \
    --arg storageId "$storage_id" \
    --arg vmssName "$vmssName" \
    --arg runid "$RUN_ID" \
    --arg nodelist "$NODELIST" \
    --arg status "$app_status" \
    --arg elapsed $elapsed_time \
    --arg nodes $NODES \
    --arg cores $CORES \
    --arg ppn $PPN > app_bench.json
$DIR/send_to_loganalytics.sh "$app_name" app_bench.json

if [ -f metrics.json ]; then
    # inject the run id into metrics
    jq '. = [ .[] | .runId=$runid]' \
         --arg runid "$RUN_ID" \
         metrics.json >  app_bench_metrics.json
    $DIR/send_to_loganalytics.sh "${app_name}_metrics" app_bench_metrics.json
fi

popd
exit $return_code