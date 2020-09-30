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

**IMPORTANT:** Ensure that the subscription limits allow the allocation in the desired region of the specified maximum number of instances for a given VM SKU. Inability to deploy the requested number of VMs will result in the job pending in configuration state for `ResumeTimeout` before being cancelled for node failure.

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

## Step 6 - Using the Slurm cluster

### Slurm configuration

The Slurm configuration applied by AzureHPC provides the following functionalities:
* Nodes can host multiple jobs as CPU cores and memory are set as consumable resources.
* Slurm uses Linux cgroups to constrain CPU cores and memory allocated to jobs and track their processes.
* Processes locality can be selected for each job through the `--cpu-bind` option (see https://slurm.schedmd.com/mc_support.html). The number of sockets matches the amount of NUMA nodes present on the node.
* On nodes with hyperthreading, physical cores (and their correspondent logical core) are allocated to jobs to prevent processes fron different jobs to share the same physical CPU core. For this reason on VM SKUs with active hyperthreading only half the amount of cores can be requested per node (e.g. 32 cores on `D64d_v4` VMs).
* Since each partition contains VMs from a single SKU, the default amount of memory per CPU core assigned to jobs (if not explicitly specified via `--mem` or equivalent) corresponds to the actual amount of memory divided by the total number of CPU cores on the node.
* 5% of the total amount of memory available on the node (up to a maximum of 5 GB) is dedicated to operating system processes to guarantee system stability and performance.
* No time restrictions are applied to the job duration. However users can specify a maximum job duration with the `--time` option.

### Checking the status of the nodes

To gather information regarding the status of the nodes in the cluster use the `sinfo` command. Here is an example of the output:

```
[hpcuser@headnode ~]$ sinfo
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
d64dv4       up   infinite      2  alloc d64dv4-[0001-0002]
d64dv4       up   infinite      2 alloc# d64dv4-[0003-0005]
d64dv4       up   infinite     28  idle~ d64dv4-[0006-0030]
hb60rs       up   infinite     30    mix hb60rs-0001
hb60rs       up   infinite     30  idle% hb60rs-0002
hb60rs       up   infinite     30  idle~ hb60rs-[0003-0030]
```

The symbols shown at the end of the state string indicate the power state of the nodes:
* No symbol: nodes are active and ready for jobs
* `#`: nodes are resuming (allocating VMs)
* `~`: nodes are suspended (VMs are deallocated)
* `%`: nodes are suspening (VMs are being deallocated)

The output above reports the following status:
* Nodes `d64dv4-[0006-0030]` and `hb60rs-[0003-0030]` are not in use and the VMs are deallocated
* Nodes `d64dv4-[0001-0002]` are active and all their CPUs are allocated to jobs (`alloc`)
* Node `hb60rs-0001` is active and its resources are partially allocated to running jobs (`mix`)
* VMs for nodes `d64dv4-[0003-0005]` are being deployed and all their resources are assigned to jobs in queue
* Node `hb60rs-0002` has been idle for more than `SuspendTime` (see `slurm.conf`) and is being suspended

More detailed node information can be obtained with `scontrol`:

```
[hpcuser@headnode ~]$ scontrol show node hb60rs-0001
NodeName=hb60rs-0001 Arch=x86_64 CoresPerSocket=4 
   CPUAlloc=4 CPUTot=60 CPULoad=0.75
   AvailableFeatures=HB60rs
   ActiveFeatures=HB60rs
   Gres=(null)
   NodeAddr=10.2.0.6 NodeHostName=hb60rs-0001 Port=0 Version=19.05.5
   OS=Linux 3.10.0-1127.el7.x86_64 #1 SMP Tue Mar 31 23:36:51 UTC 2020 
   RealMemory=229376 AllocMem=14948 FreeMem=220314 Sockets=15 Boards=1
   MemSpecLimit=5120
   State=MIXED+CLOUD ThreadsPerCore=1 TmpDisk=0 Weight=1 Owner=N/A MCS_label=N/A
   Partitions=hb60rs 
   BootTime=2020-09-29T17:48:54 SlurmdStartTime=2020-09-29T17:51:59
   CfgTRES=cpu=60,mem=224G,billing=60
   AllocTRES=cpu=4,mem=14948M
   CapWatts=n/a
   CurrentWatts=0 AveWatts=0
   ExtSensorsJoules=n/s ExtSensorsWatts=0 ExtSensorsTemp=n/s
```

Here we can see that in this partially allocated node (`MIXED`) only 4 CPUs and 14.6 GB of memory is currently assigned to running jobs (see `AllocTRES`).

It is important to notice that if issues are encountered while allocating new VMs, the requested nodes will be set as `down` by the scheduler. Manual intervention is required to return those jobs to an idle state after the issue has been resolved. Down nodes can be resumed with:

```
[root@headnode]# scontrol update nodename=<node_list> state=resume
```

### Running jobs

Batch jobs can be submitted by passing a batch job script to the `sbatch` command:

```
[hpcuser@headnode ~]$ sbatch test.sb
Submitted batch job 37
[hpcuser@headnode ~]$ squeue
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
                37    hb60rs  hpl_run  hpcuser CF       0:02      5 hb60rs-[0001-0005]
```

Since multiple jobs can be allocated on the same node, it is mandatory to define the number of CPU cores and memory that must be assigned to the job. If no explicit resources are requested at job submission, Slurm will assign one CPU core and the default amount of memory per core for the given VM SKU. The latter is calculated as the total amount of memory avilable on the VM minus the system reserved memory and then divided by the number of physical cores on the VM.

It is possible to request for the job all the cores and memory available on the nodes by using the `--exclusive` directive.

In the case above the resources were specified directly in the batch job script header:

```
#!/bin/bash
#SBATCH --partition=hb60rs
#SBATCH --nodes=5
#SBATCH --exclusive
#SBATCH --time=1-00:00:00
#SBATCH --job-name=hpl_run
#SBATCH --output=hpl_run_%A.out

[...]
```

Interactive jobs can be started by using the `salloc` command. Job resources can be specified in the command lines through the same options accepted by `srun`.

```
[hpcuser@headnode ~]$ salloc --ntasks=4 --nodes=1 --mem=100G --partition=hb60rs
salloc: Granted job allocation 34
salloc: Waiting for resource configuration
salloc: Nodes hb60rs-0001 are ready for job
[hpcuser@hb60rs-0001 ~]$
```

Since `salloc` is an alias for `srun` with some additional required flags, the use of `srun` as MPI launcher within the interactive shell does not work. Please use the launchers provided by the desired MPI library (e.g. `mpirun`, `mpiexec`, etc).

### Checking the status of jobs

The status of the job queue can be queried with the `squeue` command.

A job state value of `CF` means that resources are not avaliable to satisfy the job requests and additional resources are being configured by deploying new VMs.

It is important to note that if Slurm attempts to deploy more VMs than what is allowed by the Azuure subscription limits, the jobs will remain in configuration state for `ResumeTimeout` (30 minutes in the AzureHPC Slurm configuration) before being cancelled for node failure.
