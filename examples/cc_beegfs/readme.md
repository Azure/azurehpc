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

Then copy the init.sh and variables.json from examples/cc_beegfs to your working directory.

```
$ cp $azhpc_dir/examples/cc_beegfs/init.sh .
$ cp $azhpc_dir/examples/cc_beegfs/variables.json .
```

Edit the variables.json to match your environment. Leave the projectstore empty as it will be filled up with a random value by the init script. An existing keyvault should be referenced as it won't be created for you.

```json
{
    "resource_group": "my resource group",
    "location": "location",
    "key_vault": "my key vault",
    "projectstore": ""
  }
```

Run the init.sh script which will copy all the config files of the building blocks and initialize the variables by using the variables.json updated above.

```
$ ./init.sh
```

## Step 2 - Build the system

```
$ azhpc-build --no-vnet -c prereqs.json
$ azhpc-build 
```

## Step 3 - Create the PBS cluster in CycleCloud

To create a PBS cluster attached to BeeGFS:

```
$ azhpc ccbuild -c pbscycle.json
$ cyclecloud start_cluster pbscycle
```

Similarly, for a Slurm cluster:

```
$ azhpc ccbuild -c slurmcycle.json
$ cyclecloud start_cluster slurmcycle
```

## Step 4 - Connect to CycleServer UI

Retrieve the CycleServer DNS name from the azure portal

Retrieve the Cycle admin password from the logs 

```
$ grep password azhpc_install_config/install/*.log
```

Connect to the Cycle UI with hpcadmin user and the password retrieved above. Check that you have a pbscycle cluster ready and start it.
