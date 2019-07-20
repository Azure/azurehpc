#!/bin/bash

APP_VERSION="2019.04"
OPM_URL="https://azhpcscus.blob.core.windows.net/apps/opm/2019.04/opm.tar.gz"
SHARED_APP=/apps
SHARED_DATA=/data

install_dir=$SHARED_APP

cd $install_dir

echo "Ready to download and extract OPM files from $OPM_URL"

wget $OPM_URL -O - | tar zx

cd $SHARED_DATA

install_opm_data()
{
    echo "=== Cloning data"
    git clone https://github.com/OPM/opm-data.git
    chmod -R 777 opm-data
}

install_opm_data

MODULE_DIR=$SHARED_APP/modulefiles/opm
MODULE_NAME=v2019.04
function create_opm_modulefile {
echo "=== Creating modulefile"
mkdir -p ${MODULE_DIR}
cat >> ${MODULE_DIR}/${MODULE_NAME} << EOF 
#%Module 1.0
#
#  opm module for use with 'environment-modules' package:
#
prepend-path            PATH                           $install_dir/opm
prepend-path            OPM_BASE_DIR                   $install_dir/opm
prepend-path            OPM_BIN_DIR                    $install_dir/opm/opm-simulators/build/bin
EOF
}

create_opm_modulefile

cd $SHARED_DATA/opm-data/norne

echo "Creating param file"

cat << EOF > params
ecl-deck-file-name=NORNE_ATW2013.DATA
output-dir=out_parallel
output-mode=none
output-interval=10000
threads-per-process=4
EOF
