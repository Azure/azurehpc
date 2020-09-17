#!/bin/bash

# Script to be run on all compute nodes
while ! rpm -q epel-release
do
    if ! yum -y install epel-release
    then
        yum clean metadata
    fi
done

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
    if [ -e /opt/pbs/bin ]; then
        $DIR/azhpc4cycle.sh fix_pbs_limits
        $DIR/azhpc4cycle.sh pbs_enable_job_history
    fi
fi
