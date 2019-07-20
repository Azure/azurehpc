#!/bin/bash
JSON=$1

RG=`jq '.resource_group' ${JSON} | xargs`
VNET=`jq '.vnet.name' ${JSON} | xargs`
SUBNET=`jq '.resources.azhpchn.subnet' ${JSON} | xargs`
SKU_HN=`jq '.resources.azhpchn.vm_type' ${JSON} | xargs`
IMAGE_HN=`jq '.variables.image' ${JSON} | xargs`
SKU_CN=`jq '.resources.azhpccn.vm_type' ${JSON} | xargs`
#echo Create CC param file from json

PARAMS='''
{
  "MasterMachineType" : "'${SKU_HN}'",
  "MaxExecuteCoreCount" : 100,
  "ReturnProxy" : true,
  "UsePublicNetwork" : true,
  "Credentials" : "AzCat",
  "Autoscale" : true,
  "SubnetId" : "'${RG}/${VNET}/${SUBNET}'",
  "UseLowPrio" : false,
  "Region" : "westeurope",
  "MasterClusterInitSpecs" : null,
  "ExecuteMachineType" : "'${SKU_CN}'",
  "pbspro" : null,
  "ImageName" : "'${IMAGE_HN}'",
  "ExecuteNodesPublic" : false,
  "ExecuteClusterInitSpecs" : null
}
'''

echo $PARAMS

