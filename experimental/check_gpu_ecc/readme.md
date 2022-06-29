# Check GPU ECC errors reporting tool

ECC errors are quite common on modern GPU's e.g Nvidia A100. Some GPU errors are self correctable and do not have any impact on a running application, others are more severe and can cause a job to fail. Recovering from a GPU ECC error can be confusing and not be clear if the ECC problem can be recovered or if its more serious and needs to be reported. This tool provides a convenient way to see all the relevant ECC error counters and it gives guidance on what action you should take. (e.g No action, re-boot the node or submit a support ticket). 

## Prerequisites

- python3 is installed

## Usage
Run this script on a supported GPU virtual machine.
```
 ./check_gpu_ecc.py

GPU ECC error report for (Standard_ND96asr_v4, slurmcycle-hpc-pg0-1)

GPU id   RRP        RRE        RRC        RRU        EEUVS      EEUAS      EECVS      EECAS      EEUVD      EEUAD      EECVD      EECAD
======== ========== ========== ========== ========== ========== ========== ========== ========== ========== ========== ========== ==========
0        0          0          0          0          0          0          0          0          0          0          0          0
1        0          0          0          0          0          0          0          0          0          0          0          0
2        0          0          0          0          0          0          0          0          0          0          0          0
3        0          0          0          0          0          0          0          0          0          1000001    0          0
4        0          0          0          0          0          0          0          0          0          0          0          0
5        0          0          0          0          100        0          0          0          0          0          0          0
6        0          0          0          0          0          0          0          0          0          0          0          0
7        1          1          0          0          0          0          0          0          0          0          0          0

Legend
==========
RRP: Row remap pending
RRE: Row remap error
RRC: Row remap correctable error count
RRU: Row remap uncorrectable error count
EEUVS: ECC Errors uncorrectable volatile SRAM count
EEUAS: ECC Errors uncorrectable aggregate SRAM count
EECVS: ECC Errors correctable volatile SRAM count
EECAS: ECC Errors correctable aggregate SRAM count
EEUVD: ECC Errors uncorrectable volatile DRAM count
EECAD: ECC Errors uncorrectable aggregate DRAM count
EECVD: ECC Errors correctable volatile DRAM count
EECAD: ECC Errors correctable aggregate DRAM count

Warning: Detected a GPU pending row remap for GPU ID 7, please re-boot this node (slurmcycle-hpc-pg0-1) to clear this pending row remap.
Warning: Detected a GPU row remap Error for GPU ID 7, please offline this node (slurmcycle-hpc-pg0-1), get the HPC diagnostics and submit a support request.
Warning: Detected a GPU SRAM uncorrectable error for the volatile counter for GPU ID 5, please offline this node (slurmcycle-hpc-pg0-1), get the HPC diagnostics and submit a support request.
Warning: Detected a very high GPU DRAM uncorrectable error count (1000001) for the aggregate counter for GPU ID 3, please try a reboot, if the volatile counter increases again, then offline this node (slurmcycle-hpc-pg0-1), get the HPC diagnostics and submit a support request. 
```
