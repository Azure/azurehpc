# Lustre Cluster, Monitoring I/O performance with ltop

Visualisation: [config.json](https://azurehpc.azureedge.net/?o=https://raw.githubusercontent.com/Azure/azurehpc/master/examples/lustre_ltop/config.json)

This is an example of how to deploy a Lustre PFS and monitor its I/O performance using LTOP  

Resources:

* Head node (headnode)
* Compute nodes (compute)
* Lustre scaleset
  * Management/Meta-data server on first node using resource disk
  * Object storage servers using all the NVME in a RAID 0

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

# Procedure to Monitor the I/O performance of Lustre

Log-in to Management VM (in this case the first instance of the VMSS) as hpcadmin.
```
ssh lustre000000
```
Start LTOP.
```
ltop
```
You should see the following output (similar to top)
![Alt text1](/examples/lustre_ltop/images/lustre_ltop.JPG?raw=true "ltop")

>Note: if any of the OST's show up in an INACTIVE state in ltop, try remounting the OST.

See the ltop -r and -p to record and replay your I/O session.

```
ltop -h
Usage: ltop [OPTIONS]
   -f,--filesystem NAME      monitor file system NAME [default: first found]
   -t,--sample-period SECS   change display refresh [default: 1]
   -r,--record FILE          record session to FILE
   -p,--play FILE            play session from FILE
   -s,--stale-secs SECS      ignore data older than SECS [default: 12]
```
