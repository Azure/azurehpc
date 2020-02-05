# Build a PBS compute cluster

Visualisation: [config.json](https://azurehpc.azureedge.net/?o=https://raw.githubusercontent.com/Azure/azurehpc/master/examples/simple_hpc_pbs_peer_network/config.json)

This example will create an HPC cluster ready to run with PBS Pro.

## Initialise the project

To start you need to copy this directory and update the `config.json`.  Azurehpc provides the `azhpc-init` command that can help here by compying the directory and substituting the unset variables.  First run with the `-s` parameter to see which variables need to be set:

```
azhpc-init -c $azhpc_dir/examples/simple_hpc_pbs_peer_network -d simple_hpc_pbs_peer_network -s
```

The variables can be set with the `-v` option where variables are comma separated.  The output from the previous command as a starting point.  The `-d` option is required and will create a new directory name for you.  Please update to whatever `resource_group` you would like to deploy to:

```
azhpc-init -c $azhpc_dir/examples/simple_hpc_pbs_peer_network -d simple_hpc_pbs_peer_network -v resource_group=azurehpc-cluster,peer_network_resource_group=some_name,peer_vnet_name=some_name
```

> Note:  You can still update variables even if they are already set.  For example, in the command below we change the region to `westus2` and the SKU to `Standard_HC44rs`:

```
azhpc-init -c $azhpc_dir/examples/simple_hpc_pbs_peer_network -d simple_hpc_pbs_peer_network -v location=westus2,vm_type=Standard_HC44rs,resource_group=azhpc-cluster,peer_network_resource_group=some_name,peer_vnet_name=some_name
```

## Create the cluster 

```
cd simple_hpc_pbs_peer_network
azhpc-build
```

Allow ~10 minutes for deployment.  You are able to view the status VMs being deployed by running `azhpc-status` in another terminal.

## Log in the cluster

Connect to the headnode and check PBS and NFS

```
$ azhpc-connect -u hpcuser headnode
Fri Jun 28 09:18:04 UTC 2019 : logging in to headnode (via headnode6cfe86.westus2.cloudapp.azure.com)
[hpcuser@headnode ~]$ pbsnodes -avS
vnode           state           OS       hardware host            queue        mem     ncpus   nmics   ngpus  comment
--------------- --------------- -------- -------- --------------- ---------- -------- ------- ------- ------- ---------
compuc407000003 free            --       --       10.2.4.8        --            224gb      60       0       0 --
compuc407000002 free            --       --       10.2.4.7        --            224gb      60       0       0 --
[hpcuser@headnode ~]$ sudo exportfs -v
/share/apps     <world>(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
/share/data     <world>(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
/share/home     <world>(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
/mnt/resource/scratch
                <world>(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
[hpcuser@headnode ~]$
```

To check the state of the cluster you can run the following commands

```
azhpc-connect -u hpcuser headnode
qstat -Q
pbsnodes -avS
df -h
```

