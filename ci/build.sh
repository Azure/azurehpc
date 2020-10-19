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
if [ "$AZHPC_VARIABLES_RESOURCE_GROUP" = "" ]; then
    echo "variable AZHPC_VARIABLES_RESOURCE_GROUP is required"
    exit 1
fi
echo "********************************************************************"
echo "*                  INIT CONFIG VARIABLES                           *"
echo "********************************************************************"

azhpc_variables=$(printenv | grep AZHPC_VARIABLES)
for item in $azhpc_variables; do
    key=$(echo $item | cut -d '=' -f1)
    value=$(echo $item | cut -d '=' -f2)
    variable=${key#AZHPC_VARIABLES_}
    variable=${variable,,}
    if [ "$init_variables" == "" ]; then
        init_variables+="-v $variable=$value"
    else
        init_variables+=",$variable=$value"
    fi
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
#    rm -rf $PROJECT_DIR 
fi

if [ "$AZHPC_ADD_TELEMETRY" = "1" ]; then
    echo "copying the telemetry variables so they can be initialized"
    cp $BUILD_REPOSITORY_LOCALPATH/telemetry/variables.json $BUILD_REPOSITORY_LOCALPATH/$conf_dir
fi

echo "Calling azhpc-init"
azhpc-init $AZHPC_OPTION -c $BUILD_REPOSITORY_LOCALPATH/$conf_dir -d $PROJECT_DIR $init_variables || exit 1
pushd $PROJECT_DIR

if [ "$AZHPC_ADD_TELEMETRY" = "1" ]; then
    # copy pipelines common scripts to the project scripts
    mkdir ./scripts
    cp $BUILD_REPOSITORY_LOCALPATH/telemetry/* ./scripts
    chmod +x ./scripts/*.sh

    echo "Adding telemetry scripts"
    # Get cluster ID
    clusterId="$(cat /proc/sys/kernel/random/uuid | tr -d '\n-' | tr '[:upper:]' '[:lower:]')"

    # Add a cluster_id in variable in the config file to be used by telemetry scripts
    mv $config_file temp.json
    jq '.variables.cluster_id=$clusterId' --arg clusterId $clusterId temp.json > $config_file

    # merge telemetry scripts
    echo "Adding telemetry for compute nodes"
    jdoc=$(cat $BUILD_REPOSITORY_LOCALPATH/telemetry/compute_telemetry.json)
    mv $config_file temp.json
    jq '. | .install+=$install' --argjson install "$jdoc" temp.json > $config_file

    # Merge compute_telemetry variables file into config file
    cp $config_file temp.json
    jq '.variables+=$variables' --argjson variables "$(jq '.variables' variables.json)" temp.json > $config_file

fi

echo "********************************************************************"
echo "*                  BUILD RESOURCES                                 *"
echo "********************************************************************"
jq '.' $config_file
echo "Calling azhpc-build"
export PATH=$PATH:$HOME/bin # add that path for any CycleCloud calls
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
        #cat $tmp_dir/install/*.log
        grep -A10 "\[FAILURE\]" $tmp_dir/install/*.log

        # If a logging storage account is set, upload logs into blobs
        if [ -n "$AZHPC_LOG_ACCOUNT" ]; then
            echo "===================="
            echo "Upload logs in blobs"
            echo "===================="
            echo ""
            # in case of errors, upload the logs into blobs
            echo "upload $tmp_dir into blobs"
            blob="$SYSTEM_DEFINITIONNAME/$SYSTEM_JOBIDENTIFIER/$BUILD_BUILDNUMBER"
            account="$AZHPC_LOG_ACCOUNT"
            container="pipelines"
            saskey=$( \
                az storage container generate-sas \
                --account-name $account \
                --name $container \
                --permissions "rlw" \
                --start $(date --utc -d "-2 hours" +%Y-%m-%dT%H:%M:%SZ) \
                --expiry $(date --utc -d "+1 hour" +%Y-%m-%dT%H:%M:%SZ) \
                --output tsv
            )
            azcopy cp "$tmp_dir" "https://$account.blob.core.windows.net/$container/$blob?$saskey" --recursive=true
        fi
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

