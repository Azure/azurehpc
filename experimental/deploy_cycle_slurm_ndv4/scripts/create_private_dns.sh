#!/bin/bash

RG=$1
PRIVATE_ENDPOINT_NAME=$2
PRIVATE_DNS_NAME=${3:-"privatelink.mariadb.database.azure.com"}
PRIVATE_DNS_ZONE_GROUP_NAME=${4:-"privatelink-mariadb"}
DNS_LINK_NAME=${5:-"mydnslink"}
VNET_NAME=${6:-"hpcvnet"}

az network private-dns zone create --resource-group $RG --name $PRIVATE_DNS_NAME

az network private-dns link vnet create  --resource-group $RG --zone-name $PRIVATE_DNS_NAME --name $DNS_LINK_NAME \
                                         --virtual-network $VNET_NAME --registration-enabled false

az network private-endpoint dns-zone-group create --endpoint-name $PRIVATE_ENDPOINT_NAME --name default \
                                                  --private-dns-zone $PRIVATE_DNS_NAME --resource-group $RG \
                                                  --zone-name $PRIVATE_DNS_ZONE_GROUP_NAME
