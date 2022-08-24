#!/bin/bash

NAME=$1
MARIADB_SERVER=$2
MARIADB_SERVER_RG=$3
CONNECTION_NAME=$4
RG=$5
SUBSCRIPTION_ID=$6
VNET_NAME=${7:-hpcvnet}
SUBNET=${8:-conpute}

PRIVATE_CONNECTION_RESOURCE_ID="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${MARIADB_SERVER_RG}/providers/Microsoft.DBforMariaDB/servers/${MARIADB_SERVER}"
GROUP_ID=mariadbServer


az network private-endpoint create --resource-group $RG --name $NAME --vnet-name $VNET_NAME \
                                   --subnet $SUBNET --private-connection-resource-id $PRIVATE_CONNECTION_RESOURCE_ID \
                                   --connection-name $CONNECTION_NAME --group-id $GROUP_ID
