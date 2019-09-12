#!/bin/bash
applicationSecret=$1
applicationId=$2
tenantId=$3
username=$4
hostname=$5
storageAccount=$6
password=$7

wget "https://cyclecloudarm.azureedge.net/cyclecloudrelease/latest/cyclecloud_install.py"

python cyclecloud_install.py \
    --applicationSecret "$applicationSecret" \
    --applicationId "$applicationId" \
    --tenantId "$tenantId" \
    --azureSovereignCloud "public" \
    --downloadURL "https://cyclecloudarm.azureedge.net/cyclecloudrelease" \
    --cyclecloudVersion "latest" \
    --username "$username" \
    --hostname "$hostname" \
    --acceptTerms  \
    --password $password \
    --storageAccount "$storageAccount"


