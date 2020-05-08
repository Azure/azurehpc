#!/bin/bash

$RESOURCEGROUP=$1
$VMNAME=$2

az vm delete --name $VMNAME --resource-group $RESOURCEGROUP --no-wait --yes
az network nic delete --name ${VMNAME}_nic --resource-group $RESOURCEGROUP
az network public-ip delete --name ${VMNAME}_pip --resource-group $RESOURCEGROUP
az network nsg delete --name ${VMNAME}_nsg --resource-group $RESOURCEGROUP 
