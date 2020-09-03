#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
EXAMPLE_DIR=$azhpc_dir/examples
AZHPC_CONFIG=abaqus.json
AZHPC_VARIABLES=variables.json
APP_DIR=$azhpc_dir/apps/abaqus

blocks="$EXAMPLE_DIR/simple_hpc_pbs/config.json $APP_DIR/app.json"

# Copy required files
mkdir -p $DIR/scripts
cp $APP_DIR/*.sh $DIR/scripts
cp $APP_DIR/UserIntentions.xml $DIR/scripts

# Initialize config file
echo "{}" >$AZHPC_CONFIG
$azhpc_dir/init-and-merge.sh "$blocks" $AZHPC_CONFIG $AZHPC_VARIABLES
