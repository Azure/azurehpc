# Build a SLURM cluster with container suppot via Pyxis/Enroot
Visualisation: [config.json](https://azurehpc.azureedge.net/?o=https://raw.githubusercontent.com/Azure/azurehpc/master/experimental/slurm_enroot/config.json)

This example will create an HPC cluster ready to run with SLURM, Enroot, and NVIDIA GPU support.

## Initialise the project

To start you need to copy this directory and update the `config.json`.  Azurehpc provides the `azhpc-init` command that can help here by copying the directory and substituting the unset variables.  First run with the `-s` parameter to see which variables need to be set:

```
azhpc-init -c $azhpc_dir/experimental/slurm_enroot -d slurm_enroot -s
```

The variables can be set with the `-v` option where variables are comma separated. Use the output from the previous command as a starting point. The `-d` option is required and will create a new directory name for you. Please update to whatever `resource_group` you would like to deploy to:

```
azhpc-init -c $azhpc_dir/experimental/slurm_enroot -d slurm_enroot -v resource_group=azurehpc-cluster,location=westeurope
```

> Note:  You can still update variables even if they are already set.  For example, in the command below we change the region to `eastus`, the SKU to `Standard_ND40rs_v2` and image to `OpenLogic:CentOS-HPC:7_9-gen2:latest`:

```
azhpc-init -c azurehpc/experimental/slurm_enroot -d slurm_enroot -v resource_group=victor-slurm-enroot-1,location=eastus,vm_type=Standard_ND40rs_v2,hpc_image="OpenLogic:CentOS-HPC:7_9-gen2:latest"
```

## Create the cluster 

```
cd slurm_enroot
azhpc-build
```

Allow ~10-15 minutes for deployment.

## Log in the cluster

Connect to the headnode and check SLURM nodes and partitions

```
$ azhpc connect -u hpcuser headnode
[2021-07-09 17:55:37] logging directly into headnode14234.westeurope.cloudapp.azure.com
[hpcuser@headnode ~]$ sinfo -Nel
Fri Jul 09 16:55:43 2021
NODELIST       NODES PARTITION       STATE CPUS    S:C:T MEMORY TMP_DISK WEIGHT AVAIL_FE REASON              
compute000000      1  compute*        idle 44     2:22:1 354545        0      1   (null) none                
compute000003      1  compute*        idle 44     2:22:1 354545        0      1   (null) none                
[hpcuser@headnode ~]$ sinfo
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
compute*     up   infinite      2   idle compute[000000,000003]
```

## Using the cluster

Example of the interactive session using Ubuntu container via the pyxis plugin:

```
azhpc-connect -u hpcuser headnode
[hpcuser@headnode ~]$ srun --container-image=ubuntu --pty bash
pyxis: importing docker image ...
root@compute000000:/#
```

Example of using SLURM for interactive job running NVIDIA pytorch container image on GPU enabled node:

```
[hpcuser@headnode ~]$ srun --container-image='nvcr.io#nvidia/pytorch:21.07-py3' --pty bash
pyxis: importing docker image ...
root@compute000000:/workspace# python
Python 3.8.10 | packaged by conda-forge | (default, May 11 2021, 07:01:05)
[GCC 9.3.0] on linux
Type "help", "copyright", "credits" or "license" for more information.
>>> import torch
>>> torch.cuda.is_available()
True
>>>
```
