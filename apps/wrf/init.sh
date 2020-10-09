#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
EXAMPLE_DIR=$azhpc_dir/examples
AZHPC_CONFIG=config.json
AZHPC_VARIABLES=variables.json
APP_DIR=$azhpc_dir/apps/wrf

cp $EXAMPLE_DIR/simple_hpc_pbs/config.json $APP_DIR/simple_hpc_pbs.json
blocks="$APP_DIR/simple_hpc_pbs.json $APP_DIR/app.json"

# Initialize config file
echo "{}" >$AZHPC_CONFIG
$azhpc_dir/init-and-merge.sh "$blocks" $AZHPC_CONFIG $AZHPC_VARIABLES
