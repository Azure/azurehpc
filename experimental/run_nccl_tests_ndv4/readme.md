# Run NCCL tests optimally on NDv4 (A100) 

Contains a few scripts demonstrating how to run the NCCL performance tests (e.g all-reduce, all-to-all, etc) optimally
on NDV4 (A100) running Ubuntu-hpc 18.04 marketplace image. Examples of how to run this benchmark using the SLURM scheduler
and without the SLURM scheduler (e.g with a hostfile) are provided. The default NCCL test in all scripts is NCCL all-reduce.

>Note: You can change the NCCL test by setting the variable NCCL_TESTS_EXE to a different executable (default is all_reduce_perf)
 
## Prerequisites

- Ubuntu-hpc 18.04, SLURM 20.11.7-1 (Tested with Cyclecloud 8.2.2)
- Compute node(s), ND96asr_v4 or ND96amsr_v4 (Running Ubuntu-hpc 18.04)

## Run NCCL test using MPI and hostfile (No Scheduler)

First, log-on to Compute node (Needs to have MPI environment)
```
./run_nccl_tests.sh <NUMBER_OF_MPI_PROCESSES> <HOSTFILE>
```
>Note: Each NDv4 should have 8 MPI processes (so on 2 NDv4, NUM_OF_MPI_PROCESSES=16), the HOSTFILE is a text hostfile, each line has 1 IP address)

## Run NCCL test using the SLURM scheduler (e.g sbatch/srun)

Run from the scheduler or login-node.
```
sbatch -N <NUMBER_OF_NDV4_NODES> ./run_nccl_tests_slurm.slrm
```

## Expected NCCL Collective Performance on NDv4

Please consult the blob post [Performance considerations for large scale deep learning training on Azure NDv4 (A100) series](https://techcommunity.microsoft.com/t5/azure-global/performance-considerations-for-large-scale-deep-learning/ba-p/2693834)

