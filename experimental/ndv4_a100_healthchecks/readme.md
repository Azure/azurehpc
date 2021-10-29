# Healthchecks for NDv4 (A100)

It is important to run some healthchecks on the NDv4 VM's before running any large tightly-coupled job.
This directory contains a number of healthchecks that verify if host-to-device, device-to-host bandwidth, IB and GPUs are 
all working correctly. Check the scripts for the expected performance/output.

## Prerequisites

- Tested on Ubuntu-HPC 18.04
- SLURM scheduler


## Usage
>Note: Please edit all scripts to ensure the paths to output directories and executables is correct.

Get a list of hostname (assume have SLURM scheduler), remember to edit script (SLURM_NODELIST)
```
./get_slurm_hosts.sh
```
Check the generated hostlist file that it contains all your hostnames.

Build CUDA bandwithTest and ib_write_bw (with GDR support)
```
build_bandwithtest.sh
```
```
build_pertest.sh
```
Run bandwithtest, IB and GPU tests on all NDv4's using pdsh
```
./run_healthchecks.sh
```
>Note: Edit file to run individual tests
Convenience report_*.sh scripts are provided to generate simple sorted reports to help identify failed tests.

To run the ring NCCL allreduce tests (e.g on pairs of NDv4)
```
./run_ring_nccl_allreduce.sh
```
>Note: You can easily do a Ring NCCL alltoall test by just changing the executable to alltoall_perf.

## How to verify NDv4 is healthy
For The CUDA bandwidth tests all dtod, dtoh should be > 24 GB/s.
For IB ib_write_bw (GDR) tests, bandwidth should be > 180 Gb/s
For the GPU tests, there should be 8 GPU's.
For the misc IB tests, there should be 8 active devices and all should report 200 Gbps.
All DCGM tests should pass.
All NCCL allreduce tests should be > 175 GB/s (8MB message size)


## What to do if you find a NDv4 that fails the healtchecks

Submit a support ticket reporting the unhealthy NDv4

Provide the metadata for the VM (to help HPC engineers identify the VM/Host)

You can get the VM metadata by executing the following script.
```
get_vm_metadata.sh
```
>Note: If you have several NDv4 that are unhealthy, use a parallel shell like pdsh to run the script in parallel on all unhealthy VM's
