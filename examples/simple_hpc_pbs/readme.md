# Build a PBS compute cluster

This example will create an HPC cluster with a CentOS 7.6 headnode running PBS Pro 19.1 exporting a 4TB NFS space and multiple CentOS 7.6 HB60rs compute nodes

>NOTE: 
- MAKE SURE you have followed the steps in [prerequisite](../../tutorials/prerequisites.md) before proceeding here

First initialise a new project. AZHPC provides the `azhpc-init` command that will help here.  Running with the `-s` parameter will show all the variables that need to be set, e.g.

```
azhpc-init -c $azhpc_dir/examples/simple_hpc_pbs -d simple_hpc_pbs -s
```

The variables can be set with the `-v` option where variables are comma separated.  The `-d` option is required and will create a new directory name for you.

```
azhpc-init -c $azhpc_dir/examples/simple_hpc_pbs -d simple_hpc_pbs -v location=southcentralus,resource_group=azhpc-cluster,win_password=[password or secret.azhpc-vault.winadmin-secret],apps_storage_account=appstorageaccount,vm_type=Standard_HB60rs
```

Create the cluster 

```
cd simple_hpc_pbs
azhpc-build
```

Allow ~10 minutes for deployment.

To check the status of the VMs run
```
azhpc-status
```
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

To check the state of the cluster you can run the following commands
```
azhpc-connect -u hpcuser headnode
qstat -Q
pbsnodes -avS
df -h
```

