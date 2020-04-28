# GlusterFS Cluster built with L16s_v2 (NVMe SSD's)

Visualisation: [config.json](https://azurehpc.azureedge.net/?o=https://raw.githubusercontent.com/Azure/azurehpc/master/examples/glusterfs_lsv2_nvme/config.json)

This will deploy a GlusterFS distributed scale-out filesystem using local SSD's (L16s_v2), a headnode, an NFS server running on the headnode (User accounts shared home directories will be stored here), compute cluster and PBS will be deployed.

>NOTE:
- MAKE SURE YOU HAVE FOLLOWED THE STEPS IN [prerequisite](../../tutorials/prerequisites.md) before proceeding here

First initialise a new project.  AZHPC provides the `azhpc-init` command that will help here.  Running with the `-s` parameter will show all the variables that need to be set, e.g.

```
$ azhpc-init -c $azhpc_dir/examples/glusterfs_lsv2_nvme -d glusterfs_lsv2_nvme -s
Fri Jun 28 08:50:25 UTC 2019 : variables to set: "-v location=,resource_group="
```

The variables can be set with the `-v` option where variables are comma separated.  The `-d` option is required and will create a new directory name for you.

```
azhpc-init -c $azhpc_dir/examples/glusterfs_lsv2_nvme -d glusterfs_lsv2_nvme -v location=westus2,resource_group=azhpc-cluster
```

Create the cluster

```
cd glusterfs_lsv2_nvme
azhpc-build
```

Allow ~15 minutes for deployment.

To check the status of the VMs run
```
azhpc-status
```
Connect to the headnode and check PBS and BeeGFS (it will be mounted at /glusterfs)

```
$ azhpc-connect -u hpcuser headnode

Resources:

* Head node (headnode)
* Compute nodes (compute)
* GlusterFS
  * L16s_v2x4

> Note: The Hb nodes are used for the cluster.  To get best performance nodes with accelerated networking should be used.
