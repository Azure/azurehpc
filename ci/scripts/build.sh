#!/bin/bash
PROJECT_DIR=$1
if [ "$SYSTEM_DEBUG" = "true" ]; then
    set -x
    AZHPC_OPTION="--debug"
    printenv
fi
if [ "$AZHPC_CONFIG" = "" ]; then
    echo "variable AZHPC_CONFIG is required"
    exit 1
fi
if [ "$AZHPC_PIPELINE_DIR" = "" ]; then
    echo "variable AZHPC_PIPELINE_DIR is required"
    exit 1
fi
if [ "$AZHPC_VARIABLES_LOCATION" = "" ]; then
    echo "variable AZHPC_LOCATION is required"
    exit 1
fi
if [ "$AZHPC_RESOURCEGROUP" = "" ]; then
    echo "variable AZHPC_RESOURCEGROUP is required"
    exit 1
fi
if [ "$AZHPC_ADD_TELEMETRY" = "" ]; then
    export AZHPC_ADD_TELEMETRY=0
fi

azhpc_variables=$(printenv | grep AZHPC_VARIABLES)
init_variables="-v resource_group=$AZHPC_RESOURCEGROUP"
for item in $azhpc_variables; do
    key=$(echo $item | cut -d '=' -f1)
    value=$(echo $item | cut -d '=' -f2)
    variable=${key#AZHPC_VARIABLES_}
    variable=${variable,,}
    init_variables+=",$variable=$value"
done

echo $init_variables

. install.sh

conf_dir=$(dirname $AZHPC_CONFIG)
if [ "$PROJECT_DIR" = "" ]; then
    PROJECT_DIR=${conf_dir##*/}
fi
config_file=$(basename $AZHPC_CONFIG)

# clean up project dir
ls -al $PROJECT_DIR
rm -rf $PROJECT_DIR 

azhpc-init $AZHPC_OPTION -c $BUILD_REPOSITORY_LOCALPATH/$conf_dir -d $PROJECT_DIR $init_variables
pushd $PROJECT_DIR

jq '.' $config_file
azhpc-build -c $config_file $AZHPC_OPTION
return_code=$?
cat deploy*.json
ls -al
if [ "$return_code" -ne "0" ]; then
    config_file_no_path=${config_file##*/}
    config_file_no_path_or_extension=${config_file_no_path%.*}
    tmp_dir=azhpc_install_$config_file_no_path_or_extension
    if [ -d $tmp_dir ]; then
        grep -A4 "\[FAILURE\]" $tmp_dir/install/*.log
        cat $tmp_dir/install/*.log
    fi
    exit $return_code
fi

# Dump resource status only if install_from is set
install_from=$(jq -r '.install_from' $config_file)
if [ "$install_from" != "" ]; then
    azhpc-status -c $config_file $AZHPC_OPTION
fi
