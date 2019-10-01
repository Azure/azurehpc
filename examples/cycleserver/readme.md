# Deploying a CycleCloud application server with azhpc

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


The optional variables you need to set are :

| Name           | Description                                                         |
|----------------|---------------------------------------------------------------------|
| config         | `local` or the name of the configuration file to be used to install the cycle cloud CLI remotely |
| appId          | The appId associated to the `spn_name` in case of an existing SPN not owned by the user running the script |


```
$ azhpc-init -c $azhpc_dir/examples/cycleserver -d cycleserver -v location=eastus,resource_group=azhpc-cycle,key_vault=mykv,spn_name=CycleApp,projectstore=azhpccyclestore,config=local
```

Create the VM

```
$ cd cycleserver
$ azhpc-build
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


Browse to the **url** displayed to start the Cycle Web UI, connect with the **hpcadmin** user and the password retrieved above.


