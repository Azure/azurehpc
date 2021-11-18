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

Start the GPU monitor
```
./start_gpu_data_collector.sh
```

Stop the gpu_monitor
```
./stop_gpu_data_collector.sh
```
Go to your log analytics workspace to monitor your GPU's and generate dashboards.

![Alt text1](/experimental/gpu_monitoring/images/gpu-dash.png?raw=true "gpu-dash")
