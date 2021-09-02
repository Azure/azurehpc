# SLURM + Lustre Cluster

Visualisation: [config.json](https://azurehpc.azureedge.net/?o=https://raw.githubusercontent.com/Azure/azurehpc/master/examples/slurm_lustre/config.json)

Simple SLURM cluster with Lustre filesystem.

Resources:

* Head node (headnode)
* Compute nodes (compute)
* Lustre
  * Management/Meta-data server (lfsmds)
  * Object storage servers (lfsoss)


The configuration file requires the following variables to be set:

| Variable                | Description                                  |
|-------------------------|----------------------------------------------|
| resource_group          | The resource group for the project           |
