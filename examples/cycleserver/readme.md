# Deploying a CycleCloud application server with azhpc
![Build Status](https://azurecat.visualstudio.com/hpccat/_apis/build/status/azhpc/examples/cycleserver?branchName=master)

Visualisation: [config.json](https://azurehpc.azureedge.net/?o=https://raw.githubusercontent.com/Azure/azurehpc/master/examples/cycleserver/config.json)

This example shows how to silently setup a VM with CycleCloud installed and configured, plus installing and configuring the CycleCloue CLI for that instance.

>NOTE: MAKE SURE you have followed the steps in [prerequisite](../../tutorials/prerequisites.md) before proceeding here

## Initialize your environment
First initialise a new project. AZHPC provides the `azhpc-init` command that will help here.  Running with the `-s` parameter will show all the variables that need to be set, e.g.

```
$ azhpc-init -c $azhpc_dir/examples/cycleserver -d cycleserver -s
```

The variables can be set with the `-v` option where variables are comma separated.  The `-d` option is required and will create a new directory name for you.

The required variables you need to set are :

| Name           | Description                                                         |
|----------------|---------------------------------------------------------------------|
| location       | The region where the resources are created                          |
| resource_group | The resource group to put the resources                             |
| key_vault      | The Key Vault name to use. If it doesn't exists it will be created in the same `resource_group`. If it exists, make sure you have read/write access policies to secrets. |
| spn_name       | Service Principal Name to be used by CycleCloud. If it doesn't exists it will be created, you have to be owner of the subscription. If it exists you need to store its associated secret in the Key Vault `key_vault` under the secret `CycleAdminPassword`|
| projectstore   | The name of the Azure Storage to be created to store Cycel Project files |
| tenandId       | The tenantId in which the SPN has been generated                 |


The optional variables you need to set are :

| Name           | Description                                                         |
|----------------|---------------------------------------------------------------------|
| appId          | The appId associated to the `spn_name` in case of an existing SPN not owned by the user running the script |


```
$ azhpc-init -c $azhpc_dir/examples/cycleserver -d cycleserver -v location=westeurope,resource_group=azhpc-cycle,key_vault=mykv,spn_name=CycleApp,projectstore=cyclestore,appId=xxxxxx,tenandId=xxxxx
```

## Create the pre-requisites resources

```
$ cd cycleserver
$ azhpc-build -c 01-prereqs.json
```

## Create the CycleSerer VM and install CycleCloud on the CycleServer VM

```
$ azhpc-build -c 02-cycleserver.json
```

## Install the Cycle CLI on the current machine
Before running this step, please update the 03-cycle-cli.json file with the cycleserver fqdn

```json
    "image": "OpenLogic:CentOS:7.7:latest",
    "cycle_fqdn": "<update me>"
```

```
$ azhpc-build -c 03-cycle-cli.json
```

Once finished list the CycleCloud configuration 

```
$ ~/bin/cyclecloud config list
Available Configurations:
cycleserverc33bef : url = https://cycleserverc33abc.eastus.cloudapp.azure.com  [CURRENT]
```

And retrieved the Cycle Admin password
```
$ key_vault="mykv"
$ az keyvault secret show --name "CycleAdminPassword" --vault-name $key_vault -o json | jq -r '.value'
```

Browse to the **url** listed in the list above, connect with the **hpcadmin** user and the password retrieved above.

