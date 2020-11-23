#!/bin/bash

MLC_TAR_GZ_SAS_URL=$1
SHARED_APP=${2:-/apps}
APP_NAME=mlc
MODULE_DIR=${SHARED_APP}/modulefiles
APP_DIR=$SHARED_APP/$APP_NAME

AZHPC_VMSIZE=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2018-10-01" | jq -r '.compute.vmSize')
if [ "$AZHPC_VMSIZE" = "" ]; then
    echo "Unable to retrieve VM Size - Exiting"
    exit 1
fi

function get_sas_url_filename() {
   url_path=${1%\?*}
   eval $2=$(basename $url_path)
}

function create_modulefile {
mkdir -p ${MODULE_DIR}
cat << EOF >> ${MODULE_DIR}/${APP_NAME}
#%Module
set              MLCROOT           ${APP_DIR}
setenv           MLCROOT           ${APP_DIR}

append-path      PATH              \$MLCROOT/Linux
EOF
}

if [ "$AZHPC_VMSIZE" == "standard_hb60rs" ] || [ "$AZHPC_VMSIZE" == "standard_hb120rs_v2" ]; then
   NR_HUGEPAGES_1GB=$(</sys/kernel/mm/hugepages/hugepages-1048576kB/nr_hugepages)
   NR_HUGEPAGES_2MB=$(</proc/sys/vm/nr_hugepages)

   if [ $NR_HUGEPAGES_1GB -lt 20 ];then
      sudo  bash -c "echo 20 > /sys/kernel/mm/hugepages/hugepages-1048576kB/nr_hugepages"
   fi
   if [ $NR_HUGEPAGES_2MB -lt 4000 ];then
      sudo  bash -c "echo 4000 > /proc/sys/vm/nr_hugepages"
   fi
fi

if [ ! -d $APP_DIR ]; then
   mkdir -p $APP_DIR
   get_sas_url_filename $MLC_TAR_GZ_SAS_URL MLC_TAR_GZ

   cd $APP_DIR
   wget -O $MLC_TAR_GZ $MLC_TAR_GZ_SAS_URL
   tar xvf $MLC_TAR_GZ

   create_modulefile
fi
