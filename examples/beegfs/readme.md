# BeeGFS Cluster
![Build Status](https://azurecat.visualstudio.com/hpccat/_apis/build/status/azhpc/examples/beegfs?branchName=master)

Visualisation: [config.json](https://azurehpc.azureedge.net/?o=https://raw.githubusercontent.com/Azure/azurehpc/master/examples/beegfs/config.json)

This will deploy a BeeGFS PFS using ephemeral disks (L8s_v2), a headnode, an NFS server running on the headnode (User accounts shared home directories will be stored here), compute cluster and PBS will be deployed.

>NOTE:
- MAKE SURE YOU HAVE FOLLOWED THE STEPS IN [prerequisite](../../tutorials/prerequisites.md) before proceeding here

First initialise a new project.  AZHPC provides the `azhpc-init` command that will help here.  Running with the `-s` parameter will show all the variables that need to be set, e.g.

```
$ azhpc-init -c $azhpc_dir/examples/beegfs -d beegfs_azhpc -s
Fri Jun 28 08:50:25 UTC 2019 : variables to set: "-v location=,resource_group="
```

The variables can be set with the `-v` option where variables are comma separated.  The `-d` option is required and will create a new directory name for you.

```
azhpc-init -c $azhpc_dir/examples/beegfs -d beegfs_azhpc -v location=westus2,resource_group=azhpc-cluster
```

Create the cluster

```
cd beegfs_azhpc
azhpc-build
```

Allow ~15 minutes for deployment.

To check the status of the VMs run
```
azhpc-status
```
Connect to the headnode and check PBS and BeeGFS (it will be mounted at /beegfs)

```
$ azhpc-connect -u hpcuser headnode

Resources:

* Head node (headnode)
* Compute nodes (compute)
* BeeGFS
  * Management server (beegfsm)
  * Object storage servers and metadata servers(beegfssm)

> Note: The Hb nodes are used for the cluster.  To get best performance nodes with accelerated networking should be used.

