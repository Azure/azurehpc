# Build a PBS compute cluster with a Windows visualization node and TGX for visualization

This example will create an HPC cluster with a CentOS 7.6 headnode running PBS Pro 19.1 exporting a 4TB NFS space and multiple CentOS 7.6 HB60rs compute nodes; and a Windows visualization node with TGX.

>NOTE: 
- MAKE SURE you have followed the steps in [prerequisite](../../tutorials/prerequisites.md) before proceeding here
- MAKE SURE you have the TGX installer and license file uploaded in the Azure Storage blob location mentioned in setup_win_tgx.sh. You will need to provide the storage account name while initializing the config file (apps_storage_account).  

First initialise a new project. AZHPC provides the `azhpc-init` command that will help here.  Running with the `-s` parameter will show all the variables that need to be set, e.g.

```
azhpc-init -c $azhpc_dir/examples/simple_hpc_pbs_tgx -d simple_hpc_pbs_tgx -s
```

The variables can be set with the `-v` option where variables are comma separated.  The `-d` option is required and will create a new directory name for you.

```
azhpc-init -c $azhpc_dir/examples/simple_hpc_pbs_tgx -d simple_hpc_pbs_tgx -v resource_group=azhpc-cluster,win_password=[password or secret.azhpc-vault.winadmin-secret],apps_storage_account=appstorageaccount

(Optional) If you would like to change the location and the vm_type
azhpc-init -c $azhpc_dir/examples/simple_hpc_pbs_tgx -d simple_hpc_pbs_tgx -v location=southcentralus,resource_group=azhpc-cluster,win_password=[password or secret.azhpc-vault.winadmin-secret],apps_storage_account=appstorageaccount,vm_type=Standard_HB60rs
```

Create the cluster 

```
cd simple_hpc_pbs_tgx
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
azhpc-connect -u hpcuser headnode
qstat -Q
pbsnodes -avS
df -h
```


# Remote Visualization

Connect to the viznode using RDB (get the RDP file for nvnode from the Azure Portal)
- Username: hpcadmin
- Password: <winadmin-secret>

Check that Y: and Z: drives are mapped to the NFS server

> Note : Y: and Z: drives appears as disconnected while they are not.

Install TGX client on your local desktop or laptop and from their connect to the remote visualization node using <public ip address for nvnode>. 
