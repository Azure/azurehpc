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

Edit the variables.json to match your environment. Give a unique value to `projectstore`. An existing keyvault should be referenced as it won't be created for you.

```json
{
  "variables": {
    "resource_group": "my resource group",
    "location": "location",
    "key_vault": "my key vault",
    "projectstore": "unique value"
  }
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

## Step 3 - Start the PBS cluster in CycleCloud

To Start the PBS cluster attached to BeeGFS:

```
$ cyclecloud start_cluster pbscycle
```

Similarly, for a Slurm cluster:

```
$ cyclecloud start_cluster slurmcycle
```

Retrieve the cluster status by running this
```
$ cyclecloud show_cluster pbscycle | grep master | xargs | cut -d ' ' -f 2
$ cyclecloud show_nodes -c pbscycle --format=json | jq -r '.[0].State'
```
Wait until started

## Step 4 - Connect to the master

```
$ azhpc-connect jumpbox
[2020-06-16 17:15:46] logging directly into jumpbox0e70ce.westeurope.cloudapp.azure.com
Last login: Tue Jun 16 16:54:22 2020 from 137.116.212.169
[hpcadmin@jumpbox ~]$ cyclecloud connect master -c pbscycle
Connecting to hpcadmin@10.2.8.4 (pbscycle master) using SSH

 __        __  |    ___       __  |    __         __|
(___ (__| (___ |_, (__/_     (___ |_, (__) (__(_ (__|
        |

Cluster: pbscycle
Version: 7.9.6
Run List: recipe[cyclecloud], role[pbspro_master_role], recipe[cluster_init]
[hpcadmin@ip-0A020804 ~]$
```

## Step 5 - Check Beegfs is mounted

```
[hpcadmin@ip-0A020804 ~]$ df
Filesystem     1K-blocks     Used Available Use% Mounted on
devtmpfs        16451984        0  16451984   0% /dev
tmpfs           16463856        0  16463856   0% /dev/shm
tmpfs           16463856     9324  16454532   1% /run
tmpfs           16463856        0  16463856   0% /sys/fs/cgroup
/dev/sda2       30416376 10388476  20027900  35% /
/dev/sda1         505580    65552    440028  13% /boot
/dev/sda15        506608    11328    495280   3% /boot/efi
/dev/sdb1       65923564    53276  62498516   1% /mnt/resource
tmpfs            3292772        0   3292772   0% /run/user/0
beegfs_nodev   263958528   651264 263307264   1% /beegfs
tmpfs            3292772        0   3292772   0% /run/user/20002
[hpcadmin@ip-0A020804 ~]$
```

## Step 6 - Connect to CycleServer UI

Retrieve the CycleServer DNS name from the azure portal

Retrieve the Cycle admin password from the logs 

```
$ grep password azhpc_install_config/install/*.log
```

Connect to the Cycle UI with hpcadmin user and the password retrieved above. Check that you have a pbscycle cluster ready and start it.

## Step 7 - Delete the Cluster

From your deployment machine run

```
$ cyclecloud terminate_cluster pbscycle
$ cyclecloud delete_cluster pbscycle
```

## Step 8 - Drop all the resources

```
$ azhpc-destroy --no-wait
[2020-06-16 17:25:20] reading config file (config.json)
[2020-06-16 17:25:20] warning: deleting entire resource group (xps-hack)
[2020-06-16 17:25:20] you have 10s to change your mind and ctrl-c!
[2020-06-16 17:25:30] too late!
```
