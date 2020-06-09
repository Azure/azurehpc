#!/bin/bash

RESOURCE_GROUP=$1

TEMPLATE_NAME=azhpc-pbs-glusterfs
CLUSTER_NAME=pbs_azhpc_glusterfs

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


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
"Region" : "southcentralus",
"SubnetID" : "${RESOURCE_GROUP}/hpcvnet/compute",
"Credentials" : "azure",
"MasterImageName" : "OpenLogic:CentOS:7.7:latest",
"HPCImageName" : "OpenLogic:CentOS-HPC:7.7:latest",
"MasterClusterInitSpecs" : {
    "azhpc:default:1.0.0" : {
      "Order" : 10000,
      "Name" : "azhpc:default:1.0.0",
      "Spec" : "default",
      "Project" : "azhpc",
      "Version" : "1.0.0",
      "Locker" : "azure-storage"
    },
    "azhpc:glusterfs-client:1.0.0" : {
      "Order" : 10100,
      "Name" : "azhpc:glusterfs-client:1.0.0",
      "Spec" : "glusterfs-client",
      "Project" : "azhpc",
      "Version" : "1.0.0",
      "Locker" : "azure-storage"
    }
  },
"ExecuteClusterInitSpecs" : {
    "azhpc:default:1.0.0" : {
      "Order" : 10000,
      "Name" : "azhpc:default:1.0.0",
      "Spec" : "default",
      "Project" : "azhpc",
      "Version" : "1.0.0",
      "Locker" : "azure-storage"
    },
    "azhpc:glusterfs-client:1.0.0" : {
      "Order" : 10100,
      "Name" : "azhpc:glusterfs-client:1.0.0",
      "Spec" : "glusterfs-client",
      "Project" : "azhpc",
      "Version" : "1.0.0",
      "Locker" : "azure-storage"
    }
}
}
EOF

add_cluster $CLUSTER_NAME $TEMPLATE_NAME
