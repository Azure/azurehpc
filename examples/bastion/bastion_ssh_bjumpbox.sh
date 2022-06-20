#!/bin/bash

BastionName=<NOT-SET>
ResourceGroup=<NOT-SET>
TargetResourceId=<NOT-SET>
User=<NOT-SET>
SshPrivateKey=<NOT-SET>

az network bastion ssh --name $BastionName --resource-group $ResourceGroup \
--target-resource-id $TargetResourceId \
--auth-type "ssh-key" --username $User --ssh-key $SshPrivateKey
