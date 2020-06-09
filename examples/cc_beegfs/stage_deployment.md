# Building the infrastructure
Here we will explain how to deploy a full system with a VNET, JUMPBOX, CYCLESERVER and BEEGFS by using building blocks. These blocks are stored into the experimental/blocks directory.

## Step 1 - install azhpc
after cloning azhpc, source the install.sh script

## Step 2 - Initialize the configuration files
Create a working directory from where you will do the deployment and configuration update. Don't work directly from the cloned repo.

```
$ mkdir cluster
$ cd cluster
```

Then copy the init.sh script and the variables.json from examples/cc_beegfs to your working directory.

```
$ cp $azhpc_dir/examples/cc_beegfs/init.sh .
$ cp $azhpc_dir/examples/cc_beegfs/variables.json .
```

Edit the variables.json to match your environment. Leave the projectstore empty as it will be filled up with a random value by the init script. An existing keyvault should be referenced as it won't be created for you.

```json
{
    "resource_group": "[my resource group]",
    "location": "westeurope",
    "key_vault": "[my key vault]",
    "projectstore": ""
  }
```

Run the init.sh script which will copy all the config files of the building blocks and initialize the variables by using the variables.json updated above.

```
$ ./init.sh
```

## Step 2 - Build the system

```
$ azhpc-build -c vnet.json
$ azhpc-build --no-vnet -c jumpbox.json
$ azhpc-build --no-vnet -c cycle-prereqs-managed-identity.json
$ azhpc-build --no-vnet -c cycle-install-server-managed-identity.json
$ azhpc-build --no-vnet -c cycle-cli-jumpbox.json
$ azhpc-build --no-vnet -c beegfs-cluster.json
```
