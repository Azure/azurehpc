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
mkdir -p ${MODULE_DIR}
cat << EOF >> ${MODULE_DIR}/${APP_NAME}
#%Module
set              MLCROOT           ${APP_DIR}
setenv           MLCROOT           ${APP_DIR}

append-path      PATH              \$MLCROOT/Linux
EOF
}

if [ ! -d $APP_DIR ]; then
   mkdir -p $APP_DIR
   get_sas_url_filename $MLC_TAR_GZ_SAS_URL MLC_TAR_GZ

   cd $APP_DIR
   wget -O $MLC_TAR_GZ $MLC_TAR_GZ_SAS_URL
   tar xvf $MLC_TAR_GZ

   create_modulefile
fi
