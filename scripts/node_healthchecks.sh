#!/bin/bash
#
# This script will check if a node is healthy.
# - IB device presence
# - IB speed
# - GPU device presence
# - memory stream performance
# 
# Dependencies : jq, azcopy, healthchecks.json
#
# If a node is unhealty its metadata will be stored into the container for which the full_sas_key is provided. The storage structure will be YYYY/MM/DD/HH/location/vm_size
full_sas_key=$1
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
bad_node=0

# Retrieve the VM size
AZHPC_VMSIZE=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance/compute?api-version=2019-08-15" | jq -r '.vmSize')

function check_ib_device()
{
    case $AZHPC_VMSIZE in
        Standard_H16mr|Standard_H16r)
            ib_device=$(ifconfig | grep eth1 -A1 | grep inet | tr -s ' ' | cut -d' ' -f 3)
            if [ -n "$ib_device" ]; then
                IB_STATE=$(cat /sys/class/infiniband/*/ports/1/state | awk -F ":" '{print $2}' | xargs)  2>/dev/null
                IB_PHYS_STATE=$(cat /sys/class/infiniband/*/ports/1/phys_state | awk -F ":" '{print $2}'| xargs)  2>/dev/null
                IB_RATE=$(cat /sys/class/infiniband/*/ports/1/rate)  2>/dev/null
                IB_SPEED=$(/sbin/ethtool eth1 | grep "Speed:" | awk '{print $2}'| xargs)  2>/dev/null
            else
                echo "ERROR : No IB devices found"
                bad_node=1
            fi
        ;;

        Standard_HC44rs|Standard_HB60rs|Standard_HB120rs_v2)
            # Retrieve IB info
            ib_device=$(ifconfig | grep ib0 -A1 | grep inet | tr -s ' ' | cut -d' ' -f 3)
            if [ -n "$ib_device" ]; then
                IB_STATE=$(ibv_devinfo | grep state | xargs | cut -d' ' -f2)
                IB_RATE=$(ibv_devinfo -v | grep active_width | cut -d':' -f2 | xargs | cut -d' ' -f1)
                IB_SPEED=$(ibv_devinfo -v | grep active_speed | cut -d':' -f2 | xargs | cut -d'(' -f1 | xargs)
                IB_PHYS_STATE=$(ibv_devinfo -v | grep phys_state | cut -d':' -f2 | xargs | cut -d' ' -f1)
            else
                echo "ERROR : No IB devices found"
                bad_node=1
            fi
        ;;

        *)
            echo "uncovered VM Size $AZHPC_VMSIZE"
            exit 1
        ;;
    esac

    check_ib_values $AZHPC_VMSIZE "$IB_STATE" "$IB_RATE" "$IB_SPEED" "$IB_PHYS_STATE"
}

function check_ib_values()
{
    vmsize=$1
    state=$2
    rate=$3
    speed=$4
    phys_state=$5

    # Read the expected values from the dictionary config file
    dictionary=$(jq '.infiniband[] | select(.sku==$vmsize)' --arg vmsize $vmsize $DIR/healthchecks.json)
    expected=$(echo $dictionary | jq -r '.state')
    if [ "$state" != "$expected" ]; then
        echo "ERROR : IB state is $state while expected is $expected"
        bad_node=1
    fi
    expected=$(echo $dictionary | jq -r '.rate')
    if [ "$rate" != "$expected" ]; then
        echo "ERROR : IB rate is $rate while expected is $expected"
        bad_node=1
    fi
    expected=$(echo $dictionary | jq -r '.speed')
    if [ "$speed" != "$expected" ]; then
        echo "ERROR : IB speed is $speed while expected is $expected"
        bad_node=1
    fi
    expected=$(echo $dictionary | jq -r '.phys_state')
    if [ "$phys_state" != "$expected" ]; then
        echo "ERROR : IB physical state is $phys_state while expected is $expected"
        bad_node=1
    fi

}

check_ib_device

if [ $bad_node -eq 0 ]; then
    echo "VM is healthy"
else
    echo "VM is unhealthy"

    # If the sas key is not empty, get the node metadata and upload it into a blob
    if [ "$full_sas_key" != "" ]; then
        # Get simple metadata
        hostname=$(hostname)
        curl -s -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2019-08-15" > $hostname.json
        d=$(date +"%Y/%m/%d/%H")
        location=$(jq -r '.compute.location' $hostname.json)
        blob="$d/$location/$AZHPC_VMSIZE/$hostname.json"
        sas=$(echo ${full_sas_key#*\?})
        uri=$(echo ${full_sas_key%\?*})

        # if azcopy is missing install it
        if [ ! -e /usr/local/bin/azcopy ]; then
            echo "installing azcopy"
            $DIR/install-azcopy.sh
        fi
        /usr/local/bin/azcopy cp $hostname.json "$uri/$blob?$sas"
    fi
fi

exit $bad_node
