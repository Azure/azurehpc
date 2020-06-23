# AzureHPC GlusterFS and CycleCloud Integration

Outlines the procedure to access a GlusterFS PFS deployed by AzureHPC in CycleCloud (PBS or SLURM).

## Pre-requisites:

* An installed and setup Azure CycleCloud Application Server (instructions [here](https://docs.microsoft.com/en-us/azure/cyclecloud/quickstart-install-cyclecloud) or using the [azurehpc script](https://github.com/Azure/azurehpc/tree/master/examples/cycleserver))
* The Azure CycleCloud CLI (instructions [here](https://docs.microsoft.com/en-us/azure/cyclecloud/install-cyclecloud-cli))
* A GlusterFS PFS deployed with AzureHPC ([examples/glusterfs_ephemeral](https://github.com/Azure/azurehpc/tree/master/examples/glusterfs_ephemeral)).

## Overview of procedure

The "azhpc ccbuild" command will use a config file to generate AzureHPC projects/Specs and upload them to your default CycleCloud locker. A CycleCloud template parameter file will also be generated based on the parameters you specify in the config file. A default CycleCloud template (PBS or SLURM) (i.e no editing the CC template) will be used to start a CycleCloud cluster using the generated template parameter json file.

## Initialize the AzureHPC project (e.g for PBS, similar procedure for SLURM using other config file)

To start you need to copy this directory and update the `config.json`.  Azurehpc provides the `azhpc-init` command that can help here by copying the directory and substituting the unset variables.  First run with the `-s` parameter to see which variables need to be set:

```
azhpc init -c $azhpc_dir/examples/cc_glusterfs/config_pbscycle.json -d cc_pbs_glusterfs -s
```

The variables can be set with the `-v` option where variables are comma separated.  The output from the previous command as a starting point.  The `-d` option is required and will create a new directory name for you.  Please update to whatever `resource_group` you would like to deploy to:

```
azhpc-init -c $azhpc_dir/examples/cc_glusterfs/config_pbscycle.json -d cc_pbs_glusterfs -v resource_group=azurehpc-cc
```

The glusterfs_mount_host variable may be taken by running ' head -n1 azhpc_install_config/hostlists/glusterfs' in the directory the gluster file system was built in.


## Create CycleCloud Cluster with AzureHPC GlusterFS

```
cd cc_pbs_glusterfs
azhpc-build -c config_pbscycle.json --no-vnet
```
>Note : There is also a conifg file for CC SLURM integration (config_slurmcycle.json)

## Start CycleCloud Cluster
Go to CycleCloud server, find your CycleCloud Cluster (pbscycle or slurmcycle) and click on start.

## Check that GlusterFS is Mounted on Master and Nodearray resources.

```
df -h
```
