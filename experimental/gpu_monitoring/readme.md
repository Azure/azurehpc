# GPU Monitoring

GPU Monitoring is essential to get insights into how effectively your application in utilizing the GPU(s) and monitor the health of the GPU's.

Basic GPU Monitoring is demonstrated utilizing Azure Monitor log analytics. The following script are provided, collect Data Center GPU Manager dmon metrics and send it to your log  analytics workspace, start/stop GPU Monitoring (using crontab) and generate a load to test the GPU monitoring.
SLURM job ids are collected, so you can monitor for specific jobids. (Assumes exclusive jobs on nodes)

## Prerequisites

- Tested on Ubuntu-HPC 18.04
- SLURM scheduler
- Azure log analytics account and workspace.
- pdsh is installed
- View/edit scripts to ensure all paths are correct and the log analytics workspace customer_id/shared_key are updated in the scripts, the dmon fields to monitor 
  are updated in the scripts and the crontab interval is selected (default every minute)


## Usage
>Note: Please edit all scripts as outlined in the prerequisites

To see all available DCGMI dmon GPU metrics to monitor (field id's)
```
/usr/bin/dcgmi dmon -l

___________________________________________________________________________________
           Long Name                              Short Name       Field Id
___________________________________________________________________________________
driver_version                                         DRVER              1
nvml_version                                           NVVER              2
process_name                                           PRNAM              3
device_count                                           DVCNT              4
cuda_driver_version                                    CDVER              5
name                                                   DVNAM             50
brand                                                  DVBRN             51
nvml_index                                             NVIDX             52
serial_number                                          SRNUM             53
uuid                                                   UUID#             54
minor_number                                           MNNUM             55
oem_inforom_version                                    OEMVR             56
pci_busid                                              PCBID             57
pci_combined_id                                        PCCID             58
pci_subsys_id                                          PCSID             59
system_topology_pci                                    STVCI             60
system_topology_nvlink                                 STNVL             61
system_affinity                                        SYSAF             62
cuda_compute_capability                                DVCCC             63
compute_mode                                           CMMOD             65
persistance_mode                                       PMMOD             66
mig_mode                                               MGMOD             67
cuda_visible_devices                                   CUVID             68
mig_max_slices                                         MIGMS             69
cpu_affinity_0                                         CAFF0             70
cpu_affinity_1                                         CAFF1             71
cpu_affinity_2                                         CAFF2             72
cpu_affinity_3                                         CAFF3             73
ecc_inforom_version                                    EIVER             80
power_inforom_version                                  PIVER             81
inforom_image_version                                  IIVER             82
inforom_config_checksum                                CCSUM             83
inforom_config_valid                                   ICVLD             84
vbios_version                                          VBVER             85
bar1_total                                             B1TTL             90
sync_boost                                             SYBST             91
bar1_used                                              B1USE             92
bar1_free                                              B1FRE             93
sm_clock                                               SMCLK            100
memory_clock                                           MMCLK            101

etc

```

Start the GPU monitor
>Note: Remeber to edit the hostfile
```
./start_gpu_data_collector.sh
```

Stop the gpu_monitor
```
./stop_gpu_data_collector.sh
```
Go to your log analytics workspace to monitor your GPU's and generate dashboards.

![Alt text1](/experimental/gpu_monitoring/images/gpu-dash.png?raw=true "gpu-dash")
