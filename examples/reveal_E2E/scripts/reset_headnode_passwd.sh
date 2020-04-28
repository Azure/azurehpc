#!/bin/bash

RG=$1
VM_NAME=$2
USER=$3
PASSWD=$4

az vm user update \
  --resource-group $RG \
  --name $VM_NAME \
  --username $USER \
  --password $PASSWD
