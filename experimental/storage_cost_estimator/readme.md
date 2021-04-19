# HPC Storage cost comparison tool

## Overview

The  HPC storage cost estimator tool can compare the cost of various Azure HPC Storage options (IaaS Parallel Filesystems (Ephemeral and managed disks), IaaS NFS servers (ephemeral and managed disks), Azure Netapp files (standard, premium and ultra) and Blob Storage (premium, standard (hot, cold and archive)) and HPC Cache. The I/O requirements (i.e target I/O throughput and capacity) are used to configure and select the storage solutions used in the comparisons. Theoretical I/O performance is calculated using the VM, disk and storage limits/specifications. Storage cost comparisons are based on PAYGO pricing.

## Architecture


![storage_cost_architecture](/experimental/storage_cost_estimator/images/storage_cost_tool_architecture.jpg?raw=true "storage_cost")

## features

- Supports 
  - IaaS PFS (Ephemeral and managed disks)
  - IaaS NFS Server (Ephemeral and managed disks)
  - Azure Netapp Files (standard, premium and ultra)
  - Blob storage (premium, standard (hot,cold & archive))
  - Azure files (premium, standard (hot,cold))
  - HPC Cache (small, medium and large configurations)
  - ClusterStor
- Tuning of Blob transfer cost model
- flexibile report generation

## Examples

```
linuxuser@Surface_laptop:~/storage_report$ ./storage_cost.py -h
usage: storage_cost.py [-h] [-r TOTAL_REPORT_SIZE] [-g GROUP_REPORT_SIZE] [-rp READ_PERCENT] [-bs BLOCK_SIZE_MIB] [-dr]
                       [-pt PERFORMANCE_TARGET_TYPE]
                       target_performance target_capacity_TiB

positional arguments:
  target_performance    If performance_target_type is bw, then performance target is total aggregate I/O throughput in GB/s, if
                        performance_target_type is iopt then IOPS is the performance target. [float]
  target_capacity_TiB   Target total storage capacity in TiB [float]

optional arguments:
  -h, --help            show this help message and exit
  -r TOTAL_REPORT_SIZE, --total_report_size TOTAL_REPORT_SIZE
                        Total number of items/lines in the storage report [int] (default: 28)
  -g GROUP_REPORT_SIZE, --group_report_size GROUP_REPORT_SIZE
                        Total number of items/lines in each storage report group or type of storage [int] (default: 4)
  -rp READ_PERCENT, --read_percent READ_PERCENT
                        The percentage of total Blob or file I/O done by read (Used in calculating Blob/file I/O operations
                        transfer costs [float] (default: 0.6)
  -bs BLOCK_SIZE_MIB, --block_size_MiB BLOCK_SIZE_MIB
                        Blob block size used in calculation of blob or file transfer operations cost [float] (default: 32.0)
  -dr, --detailed_report
                        Print a detailed report [None] (default: False)
  -pt PERFORMANCE_TARGET_TYPE, --performance_target_type PERFORMANCE_TARGET_TYPE
                        Select the I/O performance target type (iops or bw) [string] (default: bw)
```

```
storage_cost.py 1.0 1.0

Azure Storage cost report (Target Performance = 1.0 GB/s, Target Capacity = 1.0 TiB)

               Storage                 Cost/Month(PAYGO)
====================================== ================
Blob standard_hot 1.0 TiB              $199.84
Blob premium 1.0 TiB                   $257.76
Blob standard_cold 1.0 TiB             $382.60
(PFS Standard_D8ds_v4+local_ssd)x3     $1,287.72
(PFS Standard_D2ds_v4+local_ssd)x14    $1,502.34
(PFS Standard_D4ds_v4+local_ssd)x7     $1,502.34
(PFS Standard_D8a_v4+local_ssd)x5      $1,682.65
NFS Standard_D32ds_v4+local_ssd        $1,715.50
(PFS Standard_D8s_v3+S20x3)x5          $1,932.40
(PFS Standard_D8s_v4+S20x3)x5          $2,009.05
(PFS Standard_D8as_v4+S20x3)x5         $2,009.05
NFS Standard_D48a_v4+local_ssd         $2,018.45
(PFS Standard_D4s_v4+S20x2)x10         $2,114.20
NFS Standard_D48s_v3+S20x17            $2,297.12
NFS Standard_D48s_v3+P20x7             $2,361.20
NFS Standard_D48s_v4+S20x17            $2,388.37
NFS Standard_D48as_v4+S20x17           $2,388.37
NFS Standard_D48ds_v4+local_ssd        $2,573.98
NFS Standard_D64a_v4+local_ssd         $2,690.78
File premium 16 TiB                    $3,072.00
ANF Ultra 8 TiB                        $3,217.33
ANF Premium 16 TiB                     $4,820.01
HPC Cache 2 GB/s 3 TiB                 $4,881.82
ANF Standard 62 TiB                    $9,361.94
Blob standard_archive 1.0 TiB          $29,551.20
ClusterStor 5 PiB                      $41,666.67

```
Add the -dr option to get a detailed report
```
storage_cost.py 1.0 1.0 -dr

Azure Storage cost report (Target Performance = 1.0 GB/s, Target Capacity = 1.0 TiB)

               Storage                  Capacity_TiB   Read_BW_GB/s  Write_BW_GB/s    Read_IOPS      Write_IOPS   Cost/Month(PAYGO)
====================================== ============== ============== ============== ============== ============== ================
Blob standard_hot 1.0 TiB               1.00           1.00           1.00           20,000         20,000         $199.84
Blob premium 1.0 TiB                    1.00           1.00           1.00           20,000         20,000         $257.76
Blob standard_cold 1.0 TiB              1.00           1.00           1.00           20,000         20,000         $382.60
(PFS Standard_D8ds_v4+local_ssd)x3      0.88           1.46           1.46           231,000        231,000        $1,287.72
(PFS Standard_D2ds_v4+local_ssd)x14     1.03           1.68           1.68           266,000        266,000        $1,502.34
(PFS Standard_D4ds_v4+local_ssd)x7      1.03           1.69           1.69           269,500        269,500        $1,502.34
(PFS Standard_D8a_v4+local_ssd)x5       0.98           0.94           0.47           60,000         60,000         $1,682.65
NFS Standard_D32ds_v4+local_ssd         1.17           1.94           1.94           308,000        308,000        $1,715.50
(PFS Standard_D8s_v3+S20x3)x5           7.50           0.90           0.90           7,500          7,500          $1,932.40
(PFS Standard_D8s_v4+S20x3)x5           7.50           0.90           0.90           7,500          7,500          $2,009.05
(PFS Standard_D8as_v4+S20x3)x5          7.50           0.90           0.90           7,500          7,500          $2,009.05
NFS Standard_D48a_v4+local_ssd          1.17           1.00           0.50           96,000         96,000         $2,018.45
(PFS Standard_D4s_v4+S20x2)x10          10.00          1.20           1.20           10,000         10,000         $2,114.20
NFS Standard_D48s_v3+S20x17             8.50           1.02           1.02           8,500          8,500          $2,297.12
NFS Standard_D48s_v3+P20x7              3.50           1.05           1.05           16,100         16,100         $2,361.20
NFS Standard_D48s_v4+S20x17             8.50           1.02           1.02           8,500          8,500          $2,388.37
NFS Standard_D48as_v4+S20x17            8.50           1.02           1.02           8,500          8,500          $2,388.37
NFS Standard_D48ds_v4+local_ssd         1.76           2.90           2.90           462,000        462,000        $2,573.98
NFS Standard_D64a_v4+local_ssd          1.56           1.00           0.50           96,000         96,000         $2,690.78
File premium 16 TiB                     1.00           1.00           0.70           16,400         16,400         $3,072.00
ANF Ultra 8 TiB                         8.00           1.02           1.02           64,000         64,000         $3,217.33
ANF Premium 16 TiB                      16.00          1.02           1.02           64,000         64,000         $4,820.01
HPC Cache 2 GB/s 3 TiB                  3.00           2.00           0.80           unknown        unknown        $4,881.82
ANF Standard 62 TiB                     62.00          0.99           0.99           62,000         62,000         $9,361.94
Blob standard_archive 1.0 TiB           1.00           1.00           1.00           20,000         20,000         $29,551.20
ClusterStor 5 PiB                       5,120.00       50.00          50.00          unknown        unknown        $41,666.67
```
