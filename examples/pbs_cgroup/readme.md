# Example of PBS Cgroup

Visualisation: [config.json](https://azurehpc.azureedge.net/?o=https://raw.githubusercontent.com/Azure/azurehpc/master/examples/pbs_cgroup/config.json)

This example will create an HPC cluster ready to run with PBS Pro with the Cgroup hook enabled. This will allow you to have more fine control over your resources. This is especially useful with the ND40rs_v2 sku, it has 40 cores, 8xv100 and 650 GB of memory. PBS Cgroups allows you to carve up this VM into smaller chunks (e.g Run a job on 2 gpu's, 10 cpu cores and 160GB of memory)

## Initialise the project

To start you need to copy this directory and update the `config.json`.  Azurehpc provides the `azhpc-init` command that can help here by compying the directory and substituting the unset variables.  First run with the `-s` parameter to see which variables need to be set:

```
azhpc-init -c $azhpc_dir/examples/pbs_cgroup -d pbs_cgroup -s
```

The variables can be set with the `-v` option where variables are comma separated.  The output from the previous command as a starting point.  The `-d` option is required and will create a new directory name for you.  Please update to whatever `resource_group` you would like to deploy to:
> Note: The ND40rs_v2 (8xv100) resuires a custom image (with nividia drivers installed and IB enabled).

```
azhpc-init -c $azhpc_dir/examples/pbs_cgroup -d pbs_cgroup -v resource_group=azurehpc-cluster
```

> Note:  You can still update variables even if they are already set.  For example, in the command below we change the region to `westus2` and the SKU to `Standard_HC44rs`:

```
azhpc-init -c $azhpc_dir/examples/pbs_cgroup -d pbs_cgroup -v location=westus2,vm_type=Standard_HC44rs,resource_group=azhpc-cluster
```

## Create the cluster 

```
cd simple_hpc_pbs
azhpc-build
```

Allow ~10 minutes for deployment.  You are able to view the status VMs being deployed by running `azhpc-status` in another terminal.

## Log in the cluster

Connect to the headnode and check PBS

```
$ azhpc-connect -u hpcuser headnode
Fri Jun 28 09:18:04 UTC 2019 : logging in to headnode (via headnode6cfe86.westus2.cloudapp.azure.com)
[hpcuser@headnode ~]$ pbsnodes -avS
vnode           state           OS       hardware host            queue        mem     ncpus   nmics   ngpus  comment
--------------- --------------- -------- -------- --------------- ---------- -------- ------- ------- ------- ---------
gpu000001       free            --       --       gpu000001       --            661gb      40       0       8 --

```

Use cgroups to get 2 gpu's, 10 cpus and 160GB of memory

```
qsub -I -l select=1:ncpus=10:ngpus=2:mem=160gb
```

Check that you only get 2 gpus

```
nvidia-smi

+-----------------------------------------------------------------------------+
| NVIDIA-SMI 440.64.00    Driver Version: 440.64.00    CUDA Version: 10.2     |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|===============================+======================+======================|
|   0  Tesla V100-SXM2...  Off  | 0000B57E:00:00.0 Off |                    0 |
| N/A   38C    P0    55W / 300W |      0MiB / 32510MiB |      0%      Default |
+-------------------------------+----------------------+----------------------+
|   1  Tesla V100-SXM2...  Off  | 0000EE58:00:00.0 Off |                    0 |
| N/A   41C    P0    54W / 300W |      0MiB / 32510MiB |      5%      Default |
+-------------------------------+----------------------+----------------------+
```

>Note: A job run on the requested resources will only use 2 gpu's, 10 cpu cores and 160 GB of memory. Wth Cgroups its important to specify how much memory you need because the default memory setting is very low.
