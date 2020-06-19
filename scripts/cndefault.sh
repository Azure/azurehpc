#!/bin/bash
# Script to be run on all compute nodes
if rpm -q epel-release; then
    yum -y install epel-release
fi

if rpm -q git jq htop; then
    yum -y install git jq htop
fi

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
