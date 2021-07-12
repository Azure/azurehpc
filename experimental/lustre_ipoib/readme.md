# Lustre Infiniband

Visualisation: [config.json](https://azurehpc.azureedge.net/?o=https://raw.githubusercontent.com/Azure/azurehpc/master/examples/lustre_Infiniband/config.json)

This is a deployment of Lustre using IP over Infiniband (IPoIB) using 4 Lustre Object Storage Servers and 4 Lustre clients. The size of the system may be modified via config.json. A second work is underway to use Lustre on Azure with native RDMA and should be completed shortly. The Object Storage Servers are designed to run a raid0 group using 1TB drives. This value can easily be changed inside installdrives.sh.

Please note that installdrives.sh does take some time to complete due to it having to work with only part of a virtual machine scale set (VMSS).

This deployment will only function using the Python based AzureHPC (not the BASH libexec).

Resources:

* Head node (headnode)
* Compute nodes (compute)
* Lustre
  * Management/Meta-data server (lfsmds) - identified by first lustre server
  * Object storage servers (lfsoss) - identified by next 4 lustre servers
  * Hierarchical storage management nodes (lfshsm)
  * Lustre clients exporting with samba (lfssmb) - identified by last 4 lustre servers

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
