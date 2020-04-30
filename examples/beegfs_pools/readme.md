# BeeGFS Cluster built using BeeGFS pools, ephemeral disks (temporary)  and HDD disks (persistent)
![Build Status](https://azurecat.visualstudio.com/hpccat/_apis/build/status/azhpc/examples/beegfs_pools?branchName=master)

Visualisation: [config.json](https://azurehpc.azureedge.net/?o=https://raw.githubusercontent.com/Azure/azurehpc/master/examples/beegfs_pools/config.json)

This will deploy a BeeGFS PFS using ephemeral disks (L8s_v2) and the attached Standard HDD disks, BeeGFS pools will be set-up to enable moving data between the ephemeral disk and the HDD permanent disk. A headnode, an NFS server running on the headnode (User accounts shared home directories will be stored here), compute cluster and PBS will be also be deployed.

>NOTE:
- MAKE SURE YOU HAVE FOLLOWED THE STEPS IN [prerequisite](../../tutorials/prerequisites.md) before proceeding here

First initialise a new project.  AZHPC provides the `azhpc-init` command that will help here.  Running with the `-s` parameter will show all the variables that need to be set, e.g.

```
$ azhpc-init -c $azhpc_dir/examples/beegfs_pools -d beegfs_pools -s
Fri Jun 28 08:50:25 UTC 2019 : variables to set: "-v location=,resource_group="
```

The variables can be set with the `-v` option where variables are comma separated.  The `-d` option is required and will create a new directory name for you.

```
azhpc-init -c $azhpc_dir/examples/beegfs_pools -d beegfs_pools -v location=westus2,resource_group=azhpc-cluster
```

Create the cluster

```
cd beegfs_pools
azhpc-build
```

Allow ~15 minutes for deployment.

To check the status of the VMs run
```
azhpc-status
```

Connect to the Beegfs master node (beegfsm) and check that the BeeGFS pools were set-up

```
$ azhpc-connect -u hpcuser beegfsm

```
```
$ beegfs-ctl --liststoragepools
Pool ID   Pool Description                      Targets                 Buddy Groups
======= ================== ============================ ============================
      1            Default 2,4
      2           hdd_pool 1,3

```
Writing/reading to /beegfs/hdd_pools will use the HDD disks and if you use /beegfs the ephemeral disks are used.

```
$ beegfs-df
METADATA SERVERS:
TargetID   Cap. Pool        Total         Free    %      ITotal       IFree    %
========   =========        =====         ====    =      ======       =====    =
       1      normal    1787.6GiB    1787.6GiB 100%      178.8M      178.8M 100%
       2      normal    1787.6GiB    1787.6GiB 100%      178.8M      178.8M 100%

STORAGE TARGETS:
TargetID   Cap. Pool        Total         Free    %      ITotal       IFree    %
========   =========        =====         ====    =      ======       =====    =
       1      normal    4093.7GiB    4093.7GiB 100%      409.6M      409.6M 100%
       2      normal    1787.6GiB    1787.6GiB 100%      178.8M      178.8M 100%
       3      normal    4093.7GiB    4093.7GiB 100%      409.6M      409.6M 100%
       4      normal    1787.6GiB    1787.6GiB 100%      178.8M      178.8M 100%

```
Connect to the headnode and check PBS and BeeGFS (it will be mounted at /beegfs)

```
$ azhpc-connect -u hpcuser headnode
```

Resources:

* Head node (headnode)
* Compute nodes (compute)
* BeeGFS
  * Management server (beegfsm)
  * Object storage servers and metadata servers(beegfssm)

> Note: The Hc nodes are used for the cluster.  To get best performance nodes with accelerated networking should be used.
