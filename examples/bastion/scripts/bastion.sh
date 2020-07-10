#!/bin/bash

RESOURCEGROUP=$1 
LOCATION=$2
ADDRESSPREFIXES=$3
BASTIONHOSTNAME=${4:-"bastion"}
VNETNAME=${5:-"hpcvnet"}

PUBLICIPADDRESS=${BASTIONHOSTNAME}-pip

az network vnet subnet create --address-prefixes $ADDRESSPREFIXES \
                              --name "AzureBastionSubnet" \
                              --resource-group $RESOURCEGROUP \
                              --vnet-name $VNETNAME

az network public-ip create --name $PUBLICIPADDRESS \
                            --resource-group $RESOURCEGROUP \
                            --location $LOCATION \
                            --sku "standard"

az network bastion create --name $BASTIONHOSTNAME \
                          --public-ip-address $PUBLICIPADDRESS \
                          --resource-group $RESOURCEGROUP \
                          --location $LOCATION \
                          --vnet-name $VNETNAME 
