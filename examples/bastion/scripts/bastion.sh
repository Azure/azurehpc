#!/bin/bash

RESOURCEGROUP=$1 
LOCATION=$2
ADDRESSPREFIXES=$3
BASTIONNAME=${4:-"bastion"}
PUBLICIPADDRESS=${5:-"bastion-pip"}
VNETNAME=${6:-"hpcvnet"}

az network vnet subnet create --address-prefixes $ADDRESSPREFIXES \
                              --name "AzureBastionSubnet" \
                              --resource-group $RESOURCEGROUP \
                              --vnet-name $VNETNAME
                               

az network bastion create --name $BASTIONNAME \
                          --public-ip-address $PUBLICIPADDRESS \
                          --resource-group $RESOURCEGROUP \
                          --vnet-name $VNETNAME \
                          --location $LOCATION
