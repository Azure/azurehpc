# Lustre Cluster
![Build Status](https://azurecat.visualstudio.com/hpccat/_apis/build/status/azhpc/examples/lustre_combined?branchName=master)

Visualisation: [config.json](https://azurehpc.azureedge.net/?o=https://raw.githubusercontent.com/Azure/azurehpc/master/examples/lustre_combined/config.json)

This is a Lustre setup where a single VMSS is used.  Each VM in the scaleset 
performs the function of the OSS and HSM.  THe first VM in the scaleset is also
used for the MGS/MDS.

Resources:

* Head node (headnode)
* Compute nodes (compute)
* Lustre scaleset
  * Management/Meta-data server on first node using resource disk
  * Object storage servers using all the NVME in a RAID 0
  * Hierarchical storage management daemon on all OSS nodes

The configuration file requires the following variables to be set:

| Variable                | Description                                  |
|-------------------------|----------------------------------------------|
| resource_group          | The resource group for the project           |
| storage_account         | The storage account for HSM                  |
| storage_key             | The storage key for HSM                      |
| storage_container       | The container to use for HSM                 |
| log_analytics_lfs_name  | The name to use in log analytics             |
| log_analytics_workspace | The log analytics workspace id               |
| log_analytics_key       | The log analytics key                        |

> Note: Macros exist to get the `storage_key` using `sakey.<storage-account-name>`, `log_analytics_workspace` using `laworkspace.<resource-group>.<workspace-name>` and `log_analytics_key` using `lakey.<resource-group>.<workspace-name>`.
