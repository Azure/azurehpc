# BeeGFS Cluster

This will deploy a BeeGFS PFS using ephemeral disks (L8s_v2), a headnode, an NFS server running on the headnode (Users shared home directories will be stored here), compute cluster and PBS will be deployed.

Resources:

* Head node (headnode)
* Compute nodes (compute)
* BeeGFS
  * Management server (beegfsm)
  * Object storage servers and metadata servers(beegfssm)

> Note: The Hb nodes are used for the cluster.  To get best performance nodes with accelerated networking should be used.

