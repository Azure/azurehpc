#!/bin/bash

BastionName=$1
ResourceGroup=$2

az resource update --name $BastionName --resource-group $ResourceGroup --resource-type bastionHosts --namespace Microsoft.Network --set properties.enableIpConnect=true --set properties.enableTunneling=true
