# AzureHPC GlusterFS and CycleCloud Integration

Visualisation: [config_gluster.json](https://azurehpc.azureedge.net/?o=https://raw.githubusercontent.com/Azure/azurehpc/master/examples/cc_glusterfs/config_glusterfs.json)

Outlines the procedure to access a GlusterFS PFS deployed by AzureHPC in CycleCloud.

## Pre-requisites:

* An installed and setup Azure CycleCloud Application Server (instructions [here](https://docs.microsoft.com/en-us/azure/cyclecloud/quickstart-install-cyclecloud) or using the [azurehpc script](https://github.com/Azure/azurehpc/tree/master/examples/cycleserver))
* The Azure CycleCloud CLI (instructions [here](https://docs.microsoft.com/en-us/azure/cyclecloud/install-cyclecloud-cli))
* A GlusterFS PFS deployed with AzureHPC ([examples/glusterfs_ephemeral](https://github.com/Azure/azurehpc/tree/master/examples/glusterfs_ephemeral)), or deploy GlusterFS with config_glusterfs,json contained in this directoy.

## Overview of procedure

A jumpbox will be deployed with cyclecloud CLI. This jumpbox will be used to integrate AzureHPC BeeGFS and CycleCloud. A Cyclecloud project for BeeGFS will be created and uploaded to the CycleCloud locker. The CycleCloud Scheduler template will be modified to access the BeeGFS client specs. The Cyclecloud scheduler template will be uploaded to the locker and a CycleCloud cluster will be created (i.e. CycleCloud controls/deploys Scheduler, Master and nodearray resources, AzureHPC deploys/controls the BeeGFS PFS and other Azure resources.)

## Initialize the AzureHPC project

To start you need to copy this directory and update the `config.json`.  Azurehpc provides the `azhpc-init` command that can help here by copying the directory and substituting the unset variables.  First run with the `-s` parameter to see which variables need to be set:

```
azhpc init -c $azhpc_dir/examples/cc_glusterfs -d cc_glusterfs -s
```

The variables can be set with the `-v` option where variables are comma separated.  The output from the previous command as a starting point.  The `-d` option is required and will create a new directory name for you.  Please update to whatever `resource_group` you would like to deploy to:

```
azhpc-init -c $azhpc_dir/examples/cc_glusterfs -d cc_glusterfs -v resource_group=azurehpc-jumpbox
```

> Note:  You can still update variables even if they are already set.  For example, in the command below we change the region to `westus2` and the SKU to `Standard_D16s_v3`:

```
azhpc-init -c $azhpc_dir/examples/cc_glusterfs -d cc_glusterfs -v location=westus2,vm_type=Standard_D16s_v3,resource_group=azhpc-jumpbox
```

## Deploy the Jumpbox and CycleCloud CLI with AzureHPC

```
cd cc_glusterfs
azhpc build -c config_jumpbox.json
```

## Deploy GlusterFS with AzureHPC

```
cd cc_glusterfs
azhpc build -c config_glusterfs.json
```

Allow ~20 minutes for deployments.  You are able to view the status VMs being deployed by running `azhpc status` in another terminal.

## Git clone AzxureHPC repository on Jumpbox

We will need the AzureHPC scripts and cyclecloud directories.
```
git clone https://github.com/Azure/azurehpc.git
```

## Log in the Jumpbox

Connect to the jumpbox

```
$ azhpc connect -c config_jumpbox.json jumpbox
```

## Upload azhpc specs to CycleCloud locker

```
cd azurehpc/cyclecloud/azhpc
cyclecloud project default_locker azure-storage
cyclecloud project upload
```
 
## Create CycleCloud Cluster with AzureHPC GlusterFS

```
cd cc_glusterfs
./pbs_glusterfs_cc_cluster.sh <RESOURCE-GROUP>
```
>Note : The RESOURCE-GROUP argument is used to locate the compute subnet that CycleCloud will use to deploy the Master and nodearray resources. Review/Edit the CycleCloud template parameters json file for your deployment/customization.
The CC cluster will be deployed using a base PBS CC template, the azhpc specs (glusterfs) are referenced in the CC template parameter json file (and not in the CC template).

## Check that GlusterFS is Mounted on Master and Nodearray resources.

```
df -h
```
