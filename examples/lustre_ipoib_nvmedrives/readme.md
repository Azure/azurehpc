# Lustre Infiniband

Visualisation: [config.json](https://azurehpc.azureedge.net/?o=https://raw.githubusercontent.com/Azure/azurehpc/master/examples/lustre_Infiniband/config.json)

This is a deployment of Lustre using the available infiniband network. This solution has been designed to work with either IP over infiniband or true Remote Direct Memory Access(RDMA), although only the IPoIB version has been developed thus far. This particular deployment will use NVMe drives for the OSSes and MDSes.

This deployment will only function using the Python based AzureHPC (not the BASH libexec).

Resources:

* Head node (headnode)
* Compute nodes (compute)
* Lustre
  * Management/Meta-data server (lfsmds)
  * Object storage servers (lfsoss)
  * Hierarchical storage management nodes (lfshsm)
  * Lustre client exporting with samba (lfssmb)

> Note: The HC nodes are used for the cluster, although this node type may be easily changed by use of the vm_type variable for lustre inside config.json.

The configuration file requires the following variables to be set:

| Variable                | Description                                  |
|-------------------------|----------------------------------------------|
| resource_group          | The resource group for the project           |
| storage_account         | The storage account for HSM                  |
| storage_key             | The storage key for HSM                      |
| storage_container       | The container to use for HSM                 |
| log_analytics_lfs_name  | The lustre filesystem name for Log Analytics |
| la_resourcegroup        | The resource group for Log Analytics         |
| la_name                 | The Log Analytics Workspace name             |
 
> Note: you can remove log anaytics and/or HSM from the config file if not required.

> Note: Key Vault should be used for the keys to keep them out of the config files.
