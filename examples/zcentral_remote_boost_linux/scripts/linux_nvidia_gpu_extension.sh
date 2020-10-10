#!/bin/bash

RESOURCE_GROUP=$1
VM_NAME=$2

az vm extension set \
   --resource-group $RESOURCE_GROUP \
   --vm-name $VM_NAME \
   --name NvidiaGpuDriverLinux \
   --publisher Microsoft.HpcCompute \
   --version 1.3

sleep 180
