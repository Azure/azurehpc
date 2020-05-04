# Building a simple PBS compute cluster with a Windows visualization node (ANF will be used for User accounts and scratch storage)
![Build Status](https://azurecat.visualstudio.com/hpccat/_apis/build/status/azhpc/examples/anf-full?branchName=master)

Visualisation: [config.json](https://azurehpc.azureedge.net/?o=https://raw.githubusercontent.com/Azure/azurehpc/master/examples/anf_full/config.json), [NFS_ANF.json](https://azurehpc.azureedge.net/?o=https://raw.githubusercontent.com/Azure/azurehpc/master/examples/anf_full/NFS_ANF.json)


This example will create an HPC cluster with a CentOS 7.6 headnode running PBS Pro 19.1, a 4TB Azure netapp files volume and several CentOS 7.6 HC44 compute nodes; and a Windows visualization node.

>NOTE: 
- MAKE SURE YOU HAVE FOLLOWED THE STEPS IN [prerequisite](../../tutorials/prerequisites.md) before proceeding here
- MAKE SURE you have the HP RGS installer and license file uploaded in the Azure Storage blob location mentioned in setup_win_rgs.sh. You will need to provide the storage account name while initializing the config file (apps_storage_account).

First initialise a new project.  AZHPC provides the `azhpc-init` command that will help here.  Running with the `-s` parameter will show all the variables that need to be set, e.g.

```
$ azhpc-init -c $azhpc_dir/examples/anf_full -d anf_full -s
Fri Jun 28 08:50:25 UTC 2019 : variables to set: "-v apps_storage_account=,location=,resource_group=,win_password="
```

The variables can be set with the `-v` option where variables are comma separated.  The `-d` option is required and will create a new directory name for you.

```
azhpc-init -c $azhpc_dir/examples/anf_full -d anf_full -v location=westus2,resource_group=azhpc-cluster,win_password=[password or secret.azhpc-vault.winadmin-secret],apps_storage_account=appstorageaccount
```

> Config File Notes:
- Pool name and volume name in the same subsciption and region need to be unique. If ANF fails to build, try changing the pool and volume name in the config file
- Pool size must be between 4-500 in increments of 4. (Units:TiB)
- Volume size must be between 1-100 (Units: TiB)

Create the cluster 

```
cd anf_full
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
compuc407000003 free            --       --       10.2.4.8        --            346gb      44       0       0 --
compuc407000002 free            --       --       10.2.4.7        --            346gb      44       0       0 --
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

Install RGS client on your local desktop or laptop and from their connect to the remote visualization node using <public ip address for nvnode>:42966.

# Building a simple PBS compute cluster with a Windows visualization node (NFS server  will be used for User accounts and ANF for scratch storage)

See NFS_ANF.json configuration file.
