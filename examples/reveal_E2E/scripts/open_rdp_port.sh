#!/bin/bash
RG=$1
VM_NAME=$2
az vm open-port --resource-group $RG --name $VM_NAME --port 3389

