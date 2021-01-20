# Building the infrastructure
![Build Status](https://azurecat.visualstudio.com/hpccat/_apis/build/status/azhpc/examples/cycleserver_msi?branchName=master)

Here we will explain how to deploy a full system with a VNET, JUMPBOX, CYCLESERVER 8.1 or 7.9x by using building blocks.
CycleCloud will be deployed using the azure marketplace image. 

## Step 1 - install azhpc
after cloning azhpc, source the install.sh script

```
$ git clone https://github.com/Azure/azurehpc.git
$ cd azurehpc
$ . install.sh
$ cd ..
```

## Step 2 - Initialize the configuration files
Create a working directory from where you will do the deployment and configuration update. Don't work directly from the cloned repo.

```
$ mkdir cycleserver
$ cd cycleserver
```

Then copy the init.sh and variables.json from examples/cycleserver_msi to your working directory.

```
$ cp $azhpc_dir/examples/cycleserver_msi/init.sh .
$ cp $azhpc_dir/examples/cycleserver_msi/variables.json .
```

Edit the variables.json to match your environment. Give a unique value to `uuid`. An existing keyvault can be referenced if needed.

```json
{
  "variables": {
    "resource_group": "my resource group",
    "location": "my location",
    "key_vault": "kv{{variables.uuid}}",
    "uuid": "unique value",
    "projectstore": "locker{{variables.uuid}}",
    "cc_image": "azurecyclecloud:azure-cyclecloud:cyclecloud-81:8.1.0 | azurecyclecloud:azure-cyclecloud:cyclecloud-79x:7.9.8",
    "cc_version": "8 | 7"
  }
}
```

Run the init.sh script which will copy all the config files of the building blocks and initialize the variables by using the variables.json updated above.

```
$ ./init.sh
```

## Step 2 - Build the system

The first command will create the required pre-requisites for CycleCloud like a Key Vault, generate a password and store it in the Vault.
The second command will buil all the resources and create a PBS cluster.

```
$ azhpc-build --no-vnet -c prereqs.json
$ azhpc-build 
```
The build process should take about 13 minutes.

## Step 3 - Connect to the CycleServer UI

Retrieve the CycleServer DNS name from the azure portal
```
$ azhpc-get fqdn.cycleserver
```

Retrieve the CycleCloud admin password stored into the keyvault

```
$ azhpc-get secret.{{variables.key_vault}}.{{variables.cc_password_secret_name}}
```

Connect to the CycleCloud Web Portal `https://fqdn-of-cycleserver` as `hpcadmin` and the password retrieved above.

