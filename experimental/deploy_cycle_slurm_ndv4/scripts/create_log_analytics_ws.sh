#!/bin/bash

RG=$1
WORKSPACE_NAME=${2:-"myWorkspace"}


az monitor log-analytics workspace create --resource-group $RG \
                                          --workspace-name $WORKSPACE_NAME
