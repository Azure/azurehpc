# Create an autoscaling Slurm cluster

![Build Status](https://azurecat.visualstudio.com/hpccat/_apis/build/status/azhpc/examples/slurm_autoscale?branchName=master)

Visualisation: [config.json](https://azurehpc.azureedge.net/?o=https://raw.githubusercontent.com/Azure/azurehpc/master/examples/slurm_autoscale/config.json)

This example will deploy an autoscaling cluster using the Slurm scheduler.

**Features**:
* Compute node VMs are allocated by using AzureHPC whenever required by submitted jobs and deallocated when idle for more than 5 minutes.
* Multiple partitions can be defined by using the new resource type `slurm_partition`, each containing nodes of a given SKU.
* Control groups perform cores and memory isolation allowing multiple jobs to be hosted on the same compute node.
* On VMs with hyperthreading, jobs are allocated on physical cores (and their corresponding logical cores) to prevent core sharing with other jobs.
* `salloc` is configured to submit jobs that return a shell on the allocated compute node for interactive workflows.

## Step 1 - Install AzureHPC

Clone the AzureHPC repository and source the `install.sh` script.

```
$ git clone https://github.com/Azure/azurehpc.git
$ cd azurehpc
$ . install.sh
$ cd ..
```

## Step 2 - Initialize the configuration files

Create a working directory from where you will do the deployment and configuration update. Don't work directly from the cloned repo.

```
$ mkdir my_slurm_autoscale
$ cd my_slurm_autoscale
```

Then copy the `config.json` file and `scripts` directory from `examples/slurm_autoscale` to your working directory.

```
$ cp $azhpc_dir/examples/slurm_autoscale/config.json .
$ cp -r $azhpc_dir/examples/slurm_autoscale/scripts .
```

## Step 3 - Configure the Slurm cluster

Edit the `config.json` file and add the desired Azure region and resource group where the cluster should be deployed.

```
"location": "SouthCentralUS",
"resource_group": "my-resource-group"
```

To add a partition, specify the VM type and all the desired settings by using a `slurm_partition` resource type. Partitions and nodes associated to the partition will be named after the name assigned to the resource.

```
"partition-name": {
      "type": "slurm_partition",
      "vm_type": "<VM_SKU>",
      "accelerated_networking": [true/false],
      "os_storage_sku": "[Standard_LRS/Premium_LRS]",
      "instances": "variables.instances",
      "image": "variables.hpc_image",
      "subnet": "hpc",
      "tags": [
         "nfsclient",
         "cndefault",
         "localuser",
         "munge",
         "slurmclient",
         "disable-selinux"
      ]
    }
```

The `instances` parameter defines the maximum total number of nodes that can be allocated for a partition.

## Step 4 - Build the Slurm cluster

Build the cluster with:

```
$ azhpc-build
```

## Step 5 - Access the Slurm cluster

The newly created cluster can be accessed via SSH from the working directory as follows:

```
$ azhpc-connect -u hpcuser headnode
```
