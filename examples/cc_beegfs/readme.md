# AzureHPC BeeGFS and CycleCloud Integration

Visualisation: [config.json](https://azurehpc.azureedge.net/?o=https://raw.githubusercontent.com/Azure/azurehpc/master/examples/cc_beegfs/config.json)

Outlines the procedure to access a BeeGFS PFS deployed by AzureHPC in CycleCloud.

## Pre-requisites:

* An installed and setup Azure CycleCloud Application Server (instructions [here](https://docs.microsoft.com/en-us/azure/cyclecloud/quickstart-install-cyclecloud) or using the [azurehpc script](https://github.com/Azure/azurehpc/tree/master/examples/cycleserver))
* The Azure CycleCloud CLI (instructions [here](https://docs.microsoft.com/en-us/azure/cyclecloud/install-cyclecloud-cli))
* A BeeGFS PFS deployed with AzureHPC ([examples/beegfs](https://github.com/Azure/azurehpc/tree/master/examples/beegfs))

## Overview of procedure

A jumpbox will be deployed with cyclecloud CLI. This jumpbox will be used to integrate AzureHPC BeeGFS and CycleCloud. A Cyclecloud project for BeeGFS will be created and uploaded to the CycleCloud locker. The CycleCloud Scheduler template will be modified to access the BeeGFS client specs. The Cyclecloud scheduler template will be uploaded to the locker and a CycleCloud cluster will be created (i.e. CycleCloud controls/deploys Scheduler, Master and nodearray resources, AzureHPC deploys/controls the BeeGFS PFS and other Azure resources.)

## Initialize the AzureHPC project

To start you need to copy this directory and update the `config.json`.  Azurehpc provides the `azhpc-init` command that can help here by copying the directory and substituting the unset variables.  First run with the `-s` parameter to see which variables need to be set:

```
azhpc init -c $azhpc_dir/examples/cc_beegfs -d cc_beegfs -s
```

The variables can be set with the `-v` option where variables are comma separated.  The output from the previous command as a starting point.  The `-d` option is required and will create a new directory name for you.  Please update to whatever `resource_group` you would like to deploy to:

```
azhpc-init -c $azhpc_dir/examples/cc_beegfs -d cc_beegfs -v resource_group=azurehpc-jumpbox
```

> Note:  You can still update variables even if they are already set.  For example, in the command below we change the region to `westus2` and the SKU to `Standard_D16s_v3`:

```
azhpc-init -c $azhpc_dir/examples/cc_beegfs -d cc_beegfs -v location=westus2,vm_type=Standard_D16s_v3,resource_group=azhpc-jumpbox
```

## Deploy the Jumpbox and CycleCloud CLI with AzureHPC

```
cd cc_beegfs
azhpc build
```

Allow ~10 minutes for deployment.  You are able to view the status VMs being deployed by running `azhpc status` in another terminal.

## Upload scripts and cc_beegfs directories

```
azhpc rcp -r $azhpc_dir/scripts jumpbox:.
azhpc rcp -r $azhpc_dir/examples/cc_beegfs jumpbox:.
```

## Log in the Jumpbox

Connect to the jumpbox

```
$ azhpc connect jumpbox
```

## Create BeeGFS CycleCloud project and upload to CycleCloud locker

```
cd cc_beegfs
./beegfs_cc_specs.sh
```
>Note: The AzureHPC scripts need to be located at ~/scripts (on jumpbox)
 
## Create CycleCloud Cluster with AzureHPC BeeGFS

```
cd cc_beegfs
./pbs_beegfs_cc_cluster.sh <RESOURCE-GROUP>
```
>Note : The RESOURCE-GROUP argument is used to locate the compute subnet that CycleCloud will use to deploy the Master and nodearray resources. Review/Edit the CycleCloud template parameters json file for your deployment/customization.

## Check that BeeGFS is Mounted on Master and Nodearray resources.

```
df -h
```
