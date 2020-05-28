#!/bin/bash

RESOURCEGROUP=$1
VMNAME=$2

az vm delete --name $VMNAME --resource-group $RESOURCEGROUP --no-wait --yes

az network nic ip-config update --name ${VMNAME} \
                               --resource-group $RESOURCEGROUP \
                               --nic-name ${VMNAME}_nic \
                               --remove ${VMNAME}_pip
           
az network nic delete --name ${VMNAME}_nic --resource-group $RESOURCEGROUP --no-wait
az network public-ip delete --name ${VMNAME}_pip --resource-group $RESOURCEGROUP
az network nsg delete --name ${VMNAME}_nsg --resource-group $RESOURCEGROUP
az disk delete --name ${VMNAME}_osdisk --resource-group $RESOURCEGROUP --no-wait --yes 
