#!/bin/bash

RESOURCE_GROUP=$1

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

PROJECT_DIR=cycle_projects
TEMPLATE_NAME=pbs_beegfs
CLUSTER_NAME=pbs_azhpc_beegfs

cd $HOME
if [ ! -d $PROJECT_DIR ]; then
   mkdir -p $PROJECT_DIR
fi
cd $PROJECT_DIR

mkdir cyclecloud-pbspro
cd cyclecloud-pbspro
cp $DIR/${TEMPLATE_NAME}.txt .

function add_template()
{
  name=$1
#Import the template to CycleCloud
  cyclecloud import_template $name -f ./$name.txt
}

function add_cluster()
{
  name=$1
  template=$2
  
  cyclecloud create_cluster $template $name -p $name.json

}

add_template $TEMPLATE_NAME

cat <<EOF >$CLUSTER_NAME.json
{
"MaxExecuteCoreCount" : 240,
"MasterMachineType" : "Standard_D8s_v3",
"ExecuteMachineType" : "Standard_HB60rs",
"DiskSize" : 1024,
"Region" : "southcentralus",
"SubnetID" : "${RESOURCE_GROUP}/hpcvnet/compute",
"Credentials" : "azure",
"BeeGFSMgmtHost": "beegfsm"
}
EOF

add_cluster $CLUSTER_NAME $TEMPLATE_NAME
