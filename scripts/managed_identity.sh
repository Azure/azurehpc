#!/bin/bash

echo input: $@

RESOURCEGROUP=$1
HEADNODE=$2

az vm identity assign -g ${RESOURCEGROUP} -n ${HEADNODE} -o table
SPID=`az resource list -n ${HEADNODE} -g ${RESOURCEGROUP} --query [*].identity.principalId --out tsv`
RESOURCEGROUPID=`az group show -n ${RESOURCEGROUP} | jq -r .id`
az role assignment create --assignee $SPID --role 'Contributor' --scope ${RESOURCEGROUPID} -o table
