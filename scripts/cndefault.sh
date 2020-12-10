#!/bin/bash

# Check to see which OS this is running on.
os_release=$(cat /etc/os-release | grep "^ID\=" | cut -d'=' -f 2 | sed -e 's/^"//' -e 's/"$//')

# Script to be run on all compute nodes
if [ "$os_release" == "centos" ];then
   echo "OS release: $os_release"
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
elif [ "$os_release" == "ubuntu" ];then
   echo "OS release: $os_release"
   apt update -y
   apt install build-essential -y
   apt install git jq htop unzip -y

   # change access to resource so that temp jobs can be written there
   chmod 777 /mnt
else
   echo "Unsupported OS release: $os_release"
fi

# Install azcopy
wget https://aka.ms/downloadazcopy-v10-linux -O azcopy
tar xzvf azcopy
sudo mv azcopy_*/azcopy /usr/local/bin/azcopy

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
