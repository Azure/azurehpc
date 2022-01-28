# GPU Optimization 

This directory contains scripts that help performance on GPU's (e.g NDv4, A100).

## Prerequisites

- Tested on ND96asr_v4 (A100) running Ubuntu-HPC 18.04

## Set Max application GPU clock frequencies
Setting the application GPU memory and graphics clock frequences to their maximum values can improve GPU performance.
The script max_gpu_app_clocks.sh can set the GPU's to their maximum application GPU clock frequencies or reset to the 
default application GPU clock frequencies (-r option).

To set the application maximum GPU clock frequencies.

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
>Note: The -r argument to reset the application GPU clock frequencies
