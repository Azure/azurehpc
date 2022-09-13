#!/bin/bash

RG=$1
SERVER_NAME=$2
ADMIN_USER=$3
ADMIN_PASSWORD=$4

SKU_NAME=${5:-"GP_Gen5_2"}
STORAGE_SIZE_MB=${6:-5120}
PUBLIC_NETWORK_ACCESS=${7:-"Disabled"}
SSL_ENFORCEMENT=${8:-"Enabled"}
VERSION=${9:-"10.3"}

az mariadb server show --resource-group $RG --name $SERVER_NAME
RC=$?

if [ $RC != 0 ]; then
    az mariadb server create --name $SERVER_NAME --resource-group $RG \
                             --public-network-access $PUBLIC_NETWORK_ACCESS --admin-user $ADMIN_USER \
                             --admin-password $ADMIN_PASSWORD --sku-name $SKU_NAME --ssl-enforcement $SSL_ENFORCEMENT \
                             --storage-size $STORAGE_SIZE_MB --version $VERSION
fi

#take note of the connection string
#"connectionString": "mysql defaultdb --host slurmdbsrv.mariadb.database.azure.com --user hpcadmin@slurmdbsrv --password=xxxxxxxx"

