# GPU Monitoring

GPU Monitoring is essential to get insights into how effectively your application in utilizing the GPU(s) and monitor the health of the GPU's.

Basic GPU Monitoring is demonstrated utilizing Azure Monitor log analytics. The following script are provided, collect Data Center GPU Manager dmon metrics and send it to your log  analytics workspace, start/stop GPU Monitoring (using crontab) and generate a load to test the GPU monitoring.
SLURM job ids are collected, so you can monitor for specific jobids. (Assumes exclusive jobs on nodes). The physical hostnames of the hosts on which the VM's are running are also recorded. You can use the system crontab to control the time interval for collecting data, or you can run the python collection script directly and specify the collection time interval (see the -tis argument below).

## Prerequisites

- Tested on Ubuntu-HPC 18.04
- SLURM scheduler
- Azure log analytics account and workspace.
- pdsh is installed
- View/edit scripts to ensure all paths are correct and the log analytics workspace customer_id/shared_key are updated in the scripts, the dmon fields to monitor 
  are updated in the scripts and the crontab interval is selected (default every minute)

## GPU monitoring script options

```
./gpu_data_collector.py -h
usage: gpu_data_collector.py [-h] [-dfi DCGM_FIELD_IDS] [-nle NAME_LOG_EVENT]
                             [-fgm] [-uc] [-tis TIME_INTERVAL_SECONDS]

optional arguments:
  -h, --help            show this help message and exit
  -dfi DCGM_FIELD_IDS, --dcgm_field_ids DCGM_FIELD_IDS
                        Select the DCGM field ids you would like to monitor
                        (if multiple field ids are desired then separate by commas)
                        [string] (default: 203,252,1004)
  -nle NAME_LOG_EVENT, --name_log_event NAME_LOG_EVENT
                        Select a name for the log events you want to monitor
                        (default: MyGPUMonitor)
  -fgm, --force_gpu_monitoring
                        Forces data to be sent to log analytics WS even if no
                        SLURM job is running on the node (default: False)
  -uc, --use_crontab    This script will be started by the system contab and
                        the time interval between each data collection will be
                        decided by the system crontab (if crontab is selected
                        then the -tis argument will be ignored). (default:
                        False)
  -tis TIME_INTERVAL_SECONDS, --time_interval_seconds TIME_INTERVAL_SECONDS
                        The time interval in seconds between each data
                        collection (This option cannot be used with the -uc
                        argument) (default: 30 sec)
```

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
To start the gpu monitor on a list of  nodes. The default collection time interval is 30 sec (-tis argument) and the default DCGM GPU metrics collected are
GPU Utilization (203), GPU memory used (252) and Tensor activity (1004). You can change these options.

Start the GPU monitor
>Note: Remember to edit the hostfile, and uncomment FORCE_GPU_MONITORING="-fgm" if you want do GPU for all processes on the node and not just processes related to SLURM jobs.
```
./start_gpu_data_collector.sh &
```

Stop the gpu_monitor
```
./stop_gpu_data_collector.sh
```
>Note: The log file for gpu_data_collector.py is located in /tmp/gpu_data_collector.log

Similarly, scripts are provided to use the system crontab to start the gpu data collector and decide the time interval based on the crontab parameters. In the case of crontab 
the smallest timing interval is 60 sec. (start_gpu_data_collector_cron.sh and stop_gpu_data_collector_cron.sh

Go to your log analytics workspace to monitor your GPU's and generate dashboards.

A simple log analytics query to chart the average GPU utilization for a particular slurm job would be.

```
MYGPUMonitor_CL
| where gpu_id_d in (0,1,2,3,4,5,6,7) and slurm_jobid_d == 17
| summarize avg(gpu_utilization_d) by bin(TimeGenerated, 5m)
| render timechart
```

![Alt text1](/experimental/gpu_monitoring/images/gpu-dash.png?raw=true "gpu-dash")
