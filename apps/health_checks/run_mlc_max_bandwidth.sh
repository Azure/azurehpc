#!/bin/bash

OUTDIR=$1

module use /apps/modulefiles
module load mlc

HOSTNAME=`hostname`

function set_hugepages() {
AZHPC_VMSIZE=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2018-10-01" | jq -r '.compute.vmSize')
if [ "$AZHPC_VMSIZE" = "" ]; then
    echo "Unable to retrieve VM Size - Exiting"
    exit 1
fi
if [ "$AZHPC_VMSIZE" == "Standard_HB60rs" ] || [ "$AZHPC_VMSIZE" == "Standard_HB120rs_v2" ]; then
   NR_HUGEPAGES_1GB=$(</sys/kernel/mm/hugepages/hugepages-1048576kB/nr_hugepages)
   NR_HUGEPAGES_2MB=$(</proc/sys/vm/nr_hugepages)

   if [ $NR_HUGEPAGES_1GB -lt 20 ];then
      SET_HUGEPAGES_1GB=1
      sudo  bash -c "echo 20 > /sys/kernel/mm/hugepages/hugepages-1048576kB/nr_hugepages"
   fi
   if [ $NR_HUGEPAGES_2MB -lt 4000 ];then
      SET_HUGEPAGES_2MB=1
      sudo  bash -c "echo 4000 > /proc/sys/vm/nr_hugepages"
   fi
fi
}

function unset_hugepages() {
if [ $SET_HUGEPAGES_1GB ]; then
   sudo  bash -c "echo 0 > /sys/kernel/mm/hugepages/hugepages-1048576kB/nr_hugepages"
fi
if [ $SET_HUGEPAGES_2MB ]; then
      sudo  bash -c "echo 0 > /proc/sys/vm/nr_hugepages"
fi
}

set_hugepages
cd $OUTDIR
mlc --max_bandwidth >& ${HOSTNAME}.out
unset_hugepages
