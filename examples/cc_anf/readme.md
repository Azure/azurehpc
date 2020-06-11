# AzureHPC ANF and CycleCloud Integration

Outlines the procedure to access a Azure NetApp Files deployed by AzureHPC in CycleCloud (PBS or SLURM).

## Pre-requisites:

* An installed and setup Azure CycleCloud Application Server (instructions [here](https://docs.microsoft.com/en-us/azure/cyclecloud/quickstart-install-cyclecloud) or using the [azurehpc script](https://github.com/Azure/azurehpc/tree/master/examples/cycleserver))
* The Azure CycleCloud CLI (instructions [here](https://docs.microsoft.com/en-us/azure/cyclecloud/install-cyclecloud-cli))
* Azure NetApp Files (ANF) deployed with AzureHPC ([examples/anf_full](https://github.com/Azure/azurehpc/tree/hackathon_june_2020/examples/anf_full)).

## Overview of procedure

The "azhpc ccbuild" command will use a config file to generate AzureHPC projects/Specs and upload them to your default CycleCloud locker. A CycleCloud template parameter file will also be generated based on the parameters you specify in the config file. A default CycleCloud template (PBS or SLURM) (i.e no editing the CC template) will be used to start a CycleCloud cluster using the generated template parameter json file.

## Initialize the AzureHPC project (e.g for PBS, similar procedure for SLURM using other config file)

To start you need to update the `anfcycle.json` file.  Azurehpc provides the `azhpc-init` command that can help here by copying the directory and substituting the unset variables.  First run with the `-s` parameter to see which variables need to be set:

```
azhpc init -c $azhpc_dir/examples/cc_anf/anfcycle.json -d cc_anf -s
```

The variables can be set with the `-v` option where variables are comma separated.  The output from the previous command as a starting point.  The `-d` option is required and will create a new directory name for you.  Please update to whatever `resource_group` you would like to deploy to:

```
azhpc-init -c $azhpc_dir/examples/cc_anf/anfcycle.json -d cc_anf -v resource_group=azurehpc-cc
```

## Create CycleCloud Cluster with AzureHPC GlusterFS

```
cd cc_anf
azhpc ccbuild -c anfcycle.json
```
>Note : There is also a conifg file for CC SLURM integration (config_slurmcycle.json)

## Start CycleCloud Cluster
Go to CycleCloud server, find your CycleCloud Cluster (pbscycle or slurmcycle) and click on start.

## Check that GlusterFS is Mounted on Master and Nodearray resources.

```
df -h
```

