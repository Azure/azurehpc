#!/bin/bash
#
# This script will check if a node is healthy.
# - IB device presence
# - IB speed
# - GPU device presence
# - memory stream performance

mds_api_version="2018-10-01"

# Retrieve the VM size and convert it to lowercase
AZHPC_VMSIZE=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance/compute?api-version=$mds_api_version" | jq '.vmSize')
AZHPC_VMSIZE=${AZHPC_VMSIZE,,}


function check_ib()
{
    case $AZHPC_VMSIZE in
        standard_h16mr|standard_h16r)
            ib_device=$(ifconfig | grep eth1 -A1 | grep inet | tr -s ' ' | cut -d' ' -f 3)
            if [ -n "$ib_device" ]; then
                IB_STATE=$(cat /sys/class/infiniband/*/ports/1/state | awk -F ":" '{print $2}' | xargs)  2>/dev/null
                IB_PHYS_STATE=$(cat /sys/class/infiniband/*/ports/1/phys_state | awk -F ":" '{print $2}'| xargs)  2>/dev/null
                IB_RATE=$(cat /sys/class/infiniband/*/ports/1/rate)  2>/dev/null
                IB_SPEED=$(/sbin/ethtool eth1 | grep "Speed:" | awk '{print $2}'| cut -d M -f1 | xargs)  2>/dev/null
                if [ "$IB_STATE" != "ACTIVE" ]; then
                    echo "ERROR : Bad IB state : $IB_STATE"
                    bad_node=1
                fi
            else
                echo "ERROR : No IB devices found"
                bad_node=1
            fi
        ;;

        standard_hc44rs|standard_hb60rs|standard_hb120rs_v2)
            # Retrieve IB info
            ib_device=$(ifconfig | grep ib0 -A1 | grep inet | tr -s ' ' | cut -d' ' -f 3)
            if [ -n "$ib_device" ]; then
                IB_STATE=$(ibv_devinfo | grep state | xargs | cut -d' ' -f2)
                IB_RATE=$(ibv_devinfo -v | grep active_width | cut -d':' -f2 | xargs | cut -d' ' -f1)
                IB_SPEED=$(ibv_devinfo -v | grep active_speed | cut -d':' -f2 | xargs | cut -d'(' -f1 | xargs)
                IB_PHYS_STATE=$(ibv_devinfo -v | grep phys_state | cut -d':' -f2 | xargs | cut -d' ' -f1)
                if [ "$IB_STATE" != "PORT_ACTIVE" ]; then
                    echo "ERROR : Bad IB state : $IB_STATE"
                    bad_node=1
                fi
            else
                echo "ERROR : No IB devices found"
                bad_node=1
            fi
        ;;
    esac

}