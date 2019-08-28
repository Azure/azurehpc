# Lustre Cluster

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

> Note: Key Vault should be used for the keys to keep them out of the config files.
