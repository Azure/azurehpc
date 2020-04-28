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
#conf_dir=${conf_dir##*/}
if [ "$PROJECT_DIR" = "" ]; then
    PROJECT_DIR=${conf_dir##*/}
fi
config_file=$(basename $AZHPC_CONFIG)

# clean up project dir
ls -al $PROJECT_DIR
rm -rf $PROJECT_DIR 

azhpc-init -c $BUILD_REPOSITORY_LOCALPATH/$conf_dir -d $PROJECT_DIR $init_variables
pushd $PROJECT_DIR

if [ -e $BUILD_REPOSITORY_LOCALPATH/$AZHPC_PIPELINE_DIR/compute.input ]; then
    # Inject one VMSS resource per TYPE/IMAGE pair
    if [ "$AZHPC_VARIABLES_VM_TYPE" != "" ]; then
        declare -i i=1
        for type in $AZHPC_VARIABLES_VM_TYPE
        do
            for image in $AZHPC_VARIABLES_HPC_IMAGE
            do
        #       Inject compute.json, with new name replacing Type and Image
                SED_STR="s/\"compute\":/\"compute"$i"\":/g"
                jdoc=$(jq '.compute.vm_type=$type | .compute.image=$image' --arg type $type --arg image $image $BUILD_REPOSITORY_LOCALPATH/$AZHPC_PIPELINE_DIR/compute.input | \
                    sed $SED_STR)
                mv $config_file temp.json
                jq '. | .resources+=$resource' --argjson resource "$jdoc" temp.json > $config_file
                i=$(( $i + 1 ))
            done
        done
    fi
fi

if [ "$AZHPC_ADD_TELEMETRY" = "1" ]; then
    echo "Adding telemetry scripts"
    mkdir ./scripts
    cp $BUILD_REPOSITORY_LOCALPATH/scripts/telemetry/* ./scripts
    chmod +x ./scripts/*.sh
    # Get cluster ID
    clusterId="$(cat /proc/sys/kernel/random/uuid | tr -d '\n-' | tr '[:upper:]' '[:lower:]')"

    # Add a cluster_id in variable in the config file to be used by telemetry scripts
    mv $config_file temp.json
    jq '.variables.cluster_id=$clusterId' --arg clusterId $clusterId temp.json > $config_file

    # merge telemetry scripts
    echo "Adding telemetry for compute nodes"
    jdoc=$(cat $BUILD_REPOSITORY_LOCALPATH/scripts/compute_telemetry.json)
    mv $config_file temp.json
    jq '. | .install+=$install' --argjson install "$jdoc" temp.json > $config_file

    # If Lustre is used add telemetry entries for Lustre
    is_lustre=$(grep lfsmaster $config_file | wc -l)
    if [ $is_lustre -ge 1 ]; then
        echo "Adding telemetry for Lustre"
        jdoc=$(cat $BUILD_REPOSITORY_LOCALPATH/scripts/lustre_telemetry.json)
        mv $config_file temp.json
        jq '. | .install+=$install' --argjson install "$jdoc" temp.json > $config_file
    fi

    # If Beegfs is used add telemetry entries for Beegfs
    is_beegfs=$(grep beegfssd $config_file | wc -l)
    if [ $is_beegfs -ge 1 ]; then
        echo "Adding telemetry for BeeGFS"
        jdoc=$(cat $BUILD_REPOSITORY_LOCALPATH/scripts/beegfs_telemetry.json)
        mv $config_file temp.json
        jq '. | .install+=$install' --argjson install "$jdoc" temp.json > $config_file
    fi

    # If ANF is used add telemetry entries for ANF
    is_anf=$(grep mount-anf $config_file | wc -l)
    if [ $is_anf -ge 1 ]; then
        echo "Adding telemetry for ANF"
        jdoc=$(cat $BUILD_REPOSITORY_LOCALPATH/scripts/anf_telemetry.json)
        mv $config_file temp.json
        jq '. | .install+=$install' --argjson install "$jdoc" temp.json > $config_file
    fi
fi

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

        # in case of errors, upload the logs into blobs
        echo "upload $tmp_dir into blobs"
        blob="pipelines/$SYSTEM_DEFINITIONNAME/$SYSTEM_JOBIDENTIFIER/$BUILD_BUILDNUMBER"
        account="azcathpcscus"
        container="e2e"
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

        if [ "$SYSTEM_DEBUG" = "true" ]; then
            cat $tmp_dir/install/*.log
        fi
    fi
    exit $return_code
fi

# Dump resource status only if install_from is set
install_from=$(jq -r '.install_from' $config_file)
if [ "$install_from" != "" ]; then
    azhpc-status -c $config_file $AZHPC_OPTION
fi
