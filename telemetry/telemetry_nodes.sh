#!/bin/bash
# Create a hostname.json file in the root of /data and push it to log analytics
# Pre-requisits :
#   - Log Analytics must be configured => analytics.sh must be executed before on the machine running this script
#   - azcopy need to be installed
cluster_id="$1"
write_sas_key="$2"
mds_api_version="2018-10-01"

if [ -z "$cluster_id" ]; then
    echo "cluster_id is missing"
    exit 1
fi

if [ -z "$write_sas_key" ]; then
    echo "SAS KEY is missing"
    exit 1
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
bad_node=0
hostname=$(hostname)

compute=""
iter=0
while [[ "$compute" == "" && iter -lt 3 ]]; do
    compute=$(curl -s --noproxy "*" -H Metadata:true "http://169.254.169.254/metadata/instance/compute?api-version=$mds_api_version" | jq '. | del(.publicKeys) | del(.plan) | del(.subscriptionId) | del(.azEnvironment) | del(.platformFaultDomain) | del(.platformUpdateDomain)')
    if [ "$compute" == "" ]; then
        echo "MDS not ready, waiting 20s"
        sleep 20
    fi
    iter=$((iter + 1))
done

AZHPC_VMSIZE=$(echo $compute | jq -r '.vmSize')
export AZHPC_VMSIZE=${AZHPC_VMSIZE,,}

os_release=$(cat /etc/centos-release)
kernel_release=$(uname -a | cut -d' ' -f 3)
vmssName=$(echo $compute | jq -r '.vmScaleSetName')
poolId=$cluster_id$vmssName

waagent=$(waagent --version | grep Goal | cut -d':' -f2 | xargs)
eth0=$(ifconfig | grep eth0 -A1 | grep inet | tr -s ' ' | cut -d' ' -f 3)
#maceth0=$(ifconfig | grep eth0 -A3 | grep ether | tr -s ' ' | cut -d' ' -f3 | sed 's/://g' | tr '[:lower:]' '[:upper:]')
hca_data="{}"

case $AZHPC_VMSIZE in
    standard_hc44rs|standard_hb60rs|standard_hb120rs_v2)
        # Retrieve IB info
        ib0=$(ifconfig | grep ib0 -A1 | grep inet | tr -s ' ' | cut -d' ' -f 3)
        # retrieve IB0 MAC address even if IB0 IP is missing, this will help troubleshooting the host
        #macib0=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance/network?api-version=$mds_api_version" | jq -r '.interface[1].macAddress')
        if [ -n "$ib0" ]; then
            id=$(ibv_devinfo | grep hca_id | cut -d':' -f2 | xargs)
            fw_ver=$(ibv_devinfo | grep fw_ver | cut -d':' -f2 | xargs)
            node_guid=$(ibv_devinfo | grep node_guid | xargs | cut -d' ' -f2)
            state=$(ibv_devinfo | grep state | xargs | cut -d' ' -f2)
            # extended properties
            max_device_ctx=$(ibv_devinfo -v | grep max_device_ctx | cut -d':' -f2 | xargs)
            active_width=$(ibv_devinfo -v | grep active_width | cut -d':' -f2 | xargs | cut -d' ' -f1)
            active_speed=$(ibv_devinfo -v | grep active_speed | cut -d':' -f2 | xargs | cut -d'(' -f1 | xargs)
            phys_state=$(ibv_devinfo -v | grep phys_state | cut -d':' -f2 | xargs | cut -d' ' -f1)
            hca_data="{"
            hca_data+="\"id\": \"$id\""
            hca_data+=",\"fw_ver\": \"$fw_ver\""
            hca_data+=",\"node_guid\": \"$node_guid\""
            hca_data+=",\"state\": \"$state\""
            hca_data+=",\"max_device_ctx\": \"$max_device_ctx\""
            hca_data+=",\"active_width\": \"$active_width\""
            hca_data+=",\"active_speed\": \"$active_speed\""
            hca_data+=",\"phys_state\": \"$phys_state\""
            hca_data+="}"
            if [ "$state" != "PORT_ACTIVE" ]; then
                echo "Bad IB state : $state"
                bad_node=1
            fi
        else
            hca_data="{\"state\": \"No IB devices found\"}"
            echo "No IB devices found"
            bad_node=1
        fi
    ;;
esac

if [ "$bad_node" == "1" ]; then
    # Upload node metadata in blob storage for bad nodes
    curl -s --noproxy "*" -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2019-08-15" > $hostname.json
    d=$(date +"%Y/%m/%d/%H")
    location=$(echo $compute | jq -r '.location')
    blob="badnodes/$d/$location/$AZHPC_VMSIZE/$hostname.json"
    write_sas=$(echo ${write_sas_key#*\?})
    uri=$(echo ${write_sas_key%\?*})
    /usr/local/bin/azcopy cp $hostname.json "$uri/$blob?$write_sas"
fi

echo "Dumping compute info"
echo $compute
echo "Dumping HCA info"
echo $hca_data

jq -n '.clusterId=$cluster_id | .poolid=$poolId | .hostname=$hostname | .waagent=$waagent | . += $compute | .osversion=$os_release | .kernel=$kernel | .eth0=$eth0 | .ib0=$ib0 | .hca += $hca' \
    --argjson compute "$compute" \
    --argjson hca "$hca_data" \
    --arg os_release "$os_release" \
    --arg kernel "$kernel_release" \
    --arg cluster_id "$cluster_id" \
    --arg poolId "$poolId" \
    --arg hostname "$hostname" \
    --arg waagent "$waagent" \
    --arg ib0 "$ib0" \
    --arg eth0 "$eth0"  > ~/$hostname.json

$DIR/send_to_loganalytics.sh "nodes" ~/$hostname.json || exit 1

exit $bad_node
