# GPU Optimization 

This directory contains scripts that help performance on GPU's (e.g NDv4, A100).

## Prerequisites

- Tested on ND96asr_v4 (A100) running Ubuntu-HPC 18.04

## Max application GPU clock frequencies
Setting the application GPU memory and graphics clock frequences to their maximum values can improve GPU performance.
The script max_gpu_app_clocks.sh can set the GPU's to their maximum application GPU clock frequencies or reset to the 
default application GPU clock frequencies (-r option).

To set the application maximum GPU clock frequencies (on NDv4, A100).

```
sudo ./max_gpu_app_clocks.sh
On GPU Id 0, Applications clocks set to "(MEM 1215, SM 1410)" for GPU 00000001:00:00.0
All done.
On GPU Id 1, Applications clocks set to "(MEM 1215, SM 1410)" for GPU 00000002:00:00.0
All done.
On GPU Id 2, Applications clocks set to "(MEM 1215, SM 1410)" for GPU 00000003:00:00.0
All done.
On GPU Id 3, Applications clocks set to "(MEM 1215, SM 1410)" for GPU 00000004:00:00.0
All done.
On GPU Id 4, Applications clocks set to "(MEM 1215, SM 1410)" for GPU 0000000B:00:00.0
All done.
On GPU Id 5, Applications clocks set to "(MEM 1215, SM 1410)" for GPU 0000000C:00:00.0
All done.
On GPU Id 6, Applications clocks set to "(MEM 1215, SM 1410)" for GPU 0000000D:00:00.0
All done.
On GPU Id 7, Applications clocks set to "(MEM 1215, SM 1410)" for GPU 0000000E:00:00.0
All done.
```

To reset the application GPU clock frequencies

```
sudo ./max_gpu_app_clocks.sh -r
On GPU Id 0, All done.
On GPU Id 1, All done.
On GPU Id 2, All done.
On GPU Id 3, All done.
On GPU Id 4, All done.
On GPU Id 5, All done.
On GPU Id 6, All done.
On GPU Id 7, All done.
```

To list the current and maximum application GPU clock frequencies.

```
sudo ./max_gpu_app_clocks.sh -l
GPU Id: 0, GPU memory freq (max,current)= (1215,1215) MHz, GPU graphics freq (max,current) = (1410,1095) MHz
GPU Id: 1, GPU memory freq (max,current)= (1215,1215) MHz, GPU graphics freq (max,current) = (1410,1095) MHz
GPU Id: 2, GPU memory freq (max,current)= (1215,1215) MHz, GPU graphics freq (max,current) = (1410,1095) MHz
GPU Id: 3, GPU memory freq (max,current)= (1215,1215) MHz, GPU graphics freq (max,current) = (1410,1095) MHz
GPU Id: 4, GPU memory freq (max,current)= (1215,1215) MHz, GPU graphics freq (max,current) = (1410,1095) MHz
GPU Id: 5, GPU memory freq (max,current)= (1215,1215) MHz, GPU graphics freq (max,current) = (1410,1095) MHz
GPU Id: 6, GPU memory freq (max,current)= (1215,1215) MHz, GPU graphics freq (max,current) = (1410,1095) MHz
GPU Id: 7, GPU memory freq (max,current)= (1215,1215) MHz, GPU graphics freq (max,current) = (1410,1095) MHz
```
