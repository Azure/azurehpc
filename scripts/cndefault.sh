#!/bin/bash

# Check to see if the node is able to access the network
i_cnt=0
wget -q --tries=10 --timeout=20 --spider http://google.com > /dev/null
while [[ $? != 0 ]]
do
        echo "Offline: $i_cnt"
        if [ "$i_cnt" -eq 10 ]
        then
            echo "tried 10 times to no avail. Exiting"
            exit -1
        fi  
        sleep 5
        wget -q --tries=10 --timeout=20 --spider http://google.com > /dev/null
        i_cnt=$((i_cnt+1))

done
echo "Online!!!"

# Script to be run on all compute nodes
if ! rpm -q epel-release; then
    yum -y install epel-release
fi

yum -y install git jq htop

# change access to resource so that temp jobs can be written there
chmod 777 /mnt/resource

# If running on Cycle 
# - enable METADATA access
# - remove Jetpack convergence
# - Disable Fail2Ban service
# - Fix PBS limits
if [ -e $CYCLECLOUD_HOME/bin/jetpack ]; then
    DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    $DIR/azhpc4cycle.sh enable_metada_access
    $DIR/azhpc4cycle.sh disable_jetpack_converge
    $DIR/azhpc4cycle.sh disable_fail2ban
    $DIR/azhpc4cycle.sh fix_pbs_limits
fi
