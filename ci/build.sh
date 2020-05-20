#!/bin/bash
PROJECT_DIR=$1
show_logs=${AZHPC_SHOW_LOGS,,}
if [ "$SYSTEM_DEBUG" = "true" ]; then
    set -x
    AZHPC_OPTION="--debug"
    show_logs="true"
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
    echo "variable AZHPC_VARIABLES_LOCATION is required"
    exit 1
fi
if [ "$AZHPC_RESOURCEGROUP" = "" ]; then
    echo "variable AZHPC_RESOURCEGROUP is required"
    exit 1
fi
echo "********************************************************************"
echo "*                  INIT CONFIG VARIABLES                           *"
echo "********************************************************************"
# AZHPC_UUID is set when creating the RG unique name when starting the pipeline
export AZHPC_VARIABLES_UUID=${AZHPC_UUID-azhpc}
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
if [ -d $PROJECT_DIR ]; then
    ls -al $PROJECT_DIR
    rm -rf $PROJECT_DIR 
fi

echo "Calling azhpc-init"
azhpc-init $AZHPC_OPTION -c $BUILD_REPOSITORY_LOCALPATH/$conf_dir -d $PROJECT_DIR $init_variables || exit 1
pushd $PROJECT_DIR

jq '.' $config_file

echo "********************************************************************"
echo "*                  BUILD RESOURCES                                 *"
echo "********************************************************************"
echo "Calling azhpc-build"
azhpc-build -c $config_file $AZHPC_OPTION
return_code=$?
cat deploy*.json
ls -al
if [[ "$return_code" -ne "0" ]] || [[ "$show_logs" == "true" ]]; then
    config_file_no_path=${config_file##*/}
    config_file_no_path_or_extension=${config_file_no_path%.*}
    tmp_dir=azhpc_install_$config_file_no_path_or_extension
    if [ -d $tmp_dir ]; then
        echo "============"
        echo "Dumping logs"
        echo "============"
        echo ""
        cat $tmp_dir/install/*.log
        grep -A4 "\[FAILURE\]" $tmp_dir/install/*.log
    fi
    if [ "$return_code" -ne "0" ]; then
        exit $return_code
    fi
fi

# Dump resource status only if install_from is set
install_from=$(jq -r '.install_from' $config_file)
if [ "$install_from" != "" ]; then
    echo "********************************************************************"
    echo "*                  RESOURCES UPTIME                                 *"
    echo "********************************************************************"
    azhpc-status -c $config_file $AZHPC_OPTION
else
    echo "Exiting as no scripts need to be copied on remote VMs"
    exit 0
fi

echo "********************************************************************"
echo "*                  COPY SCRIPTS                                    *"
echo "********************************************************************"
# Copy scripts
if [ "$AZHPC_SCRIPT_REMOTE_DEST" = "" ]; then
    export AZHPC_SCRIPT_REMOTE_DEST="hpcuser@headnode:/apps"
fi

# Copy Applications run scripts
echo "Copy Applications run scripts to $AZHPC_SCRIPT_REMOTE_DEST"
azhpc-scp $debug_option -c $config_file -- -r $BUILD_REPOSITORY_LOCALPATH/apps/. $AZHPC_SCRIPT_REMOTE_DEST || exit 1

# Copy pipeline library scripts
echo "Copy pipeline library scripts to $AZHPC_SCRIPT_REMOTE_DEST"
azhpc-scp $debug_option -c $config_file -- -r $BUILD_REPOSITORY_LOCALPATH/ci/scripts/. $AZHPC_SCRIPT_REMOTE_DEST/ci || exit 1

# List remote files
echo "List files copied to $AZHPC_SCRIPT_REMOTE_DEST"
remote_dir=$(echo $AZHPC_SCRIPT_REMOTE_DEST | cut -d ':' -f2)
azhpc-run $debug_option -c $config_file ls -al $remote_dir
azhpc-run $debug_option -c $config_file ls -al $remote_dir/ci

