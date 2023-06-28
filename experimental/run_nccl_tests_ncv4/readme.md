# Run NCCL tests optimally on NCv4 (A100) 

Contains a few scripts demonstrating how to run the NCCL performance tests (e.g all-reduce, all-to-all, etc) optimally
on NCV4 (A100) running Ubuntu-hpc 20.04 marketplace image. Examples of how to run this benchmark using the SLURM scheduler 
 and without the SLURM scheduler (e.g with a hostfile) are provided. The default NCCL test in all scripts is NCCL all-reduce.

>Note: You can change the NCCL test by setting the variable NCCL_TESTS_EXE to a different executable (default is all_reduce_perf)
 
## Prerequisites

- Ubuntu-hpc 20.04, SLURM 22.05.3-1 (Tested with Cyclecloud 8.4)
- Compute node(s), NC96ads_A100_v4 or NC48ads_A100_v4 (Running Ubuntu-hpc 20.04)

## Run NCCL test using MPI and hostfile (No Scheduler)

First, log-on to Compute node (Needs to have MPI environment)
```
./run_nccl_tests_nc96v4.sh <NUMBER_OF_MPI_PROCESSES> <HOSTFILE>
```
>Note: Each NC96v4 should have 4 MPI processes (so on 2 NC96v4, NUM_OF_MPI_PROCESSES=8), the HOSTFILE is a text hostfile, each line has 1 IP address). Use the run_nccl_tests_nc48v4.sh script to run on NC48v4 (2 A100). Make sure you use the correct topology/graph files and the paths to these files are correct.

## Run NCCL test using the SLURM scheduler (e.g sbatch/srun)

Run from the scheduler or login-node.
```
sbatch -N <NUMBER_OF_NDV4_NODES> ./run_nccl_tests_slurm_nc96v4.slrm
```

## Expected NCCL Collective Performance on NC_A100_v4

![Alt text1](/experimental/run_nccl_tests_ncv4/images/nccl_allreduce_nc96v4.jpg?raw=true "nccl_nc96v4")

![Alt text2](/experimental/run_nccl_tests_ncv4/images/nccl_allreduce_nc48v4.jpg?raw=true "nccl_nc48v4")
