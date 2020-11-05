#!/bin/bash

MLC_TAR_GZ_SAS_URL=$1
SHARED_APP=${2:-/apps}
APP_NAME=mlc
MODULE_DIR=${SHARED_APP}/modulefiles
APP_DIR=$SHARED_APP/$APP_NAME

function get_sas_url_filename() {
   url_path=${1%\?*}
   eval $2=$(basename $url_path)
}

function create_modulefile {
if [ ! -d ${MODULE_DIR} ]; then
mkdir -p ${MODULE_DIR}
cat << EOF >> ${MODULE_DIR}/${APP_NAME}
#%Module
set              MLCROOT           ${APP_DIR}
setenv           MLCROOT           ${APP_DIR}

append-path      PATH              \$MLCROOT/Linux
EOF
fi
}

NR_HUGEPAGES_1GB=$(</sys/kernel/mm/hugepages/hugepages-1048576kB/nr_hugepages)
NR_HUGEPAGES_2MB=$(</proc/sys/vm/nr_hugepages)


if [ $NR_HUGEPAGES_1GB -lt 20 ];then
   sudo  bash -c "echo 20 > /sys/kernel/mm/hugepages/hugepages-1048576kB/nr_hugepages"
fi
if [ $NR_HUGEPAGES_2MB -lt 4000 ];then
   sudo  bash -c "echo 4000 > /proc/sys/vm/nr_hugepages"
fi

if [ ! -d $APP_DIR ]; then
   mkdir -p $APP_DIR
   get_sas_url_filename $MLC_TAR_GZ_SAS_URL MLC_TAR_GZ

   cd $APP_DIR
   wget -O $MLC_TAR_GZ $MLC_TAR_GZ_SAS_URL
   tar xvf $MLC_TAR_GZ

   create_modulefile
fi
