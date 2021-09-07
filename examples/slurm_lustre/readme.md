# SLURM + Lustre Cluster

Visualisation: [config.json](https://azurehpc.azureedge.net/?o=https://raw.githubusercontent.com/Azure/azurehpc/master/examples/slurm_lustre/config.json)

Simple [SLURM](https://slurm.schedmd.com/documentation.html) cluster with [Lustre](https://www.lustre.org/) filesystem.

Resources:

* Head node (headnode)
* Compute nodes (compute)
* Lustre
  * Management/Meta-data server (lfsmds)
  * Object storage servers (lfsoss)


The configuration file requires the following variables to be set:

| Variable                | Description                                  |
|-------------------------|----------------------------------------------|
| resource_group          | The resource group for the project           |

## Initialise the project

To start you need to copy this directory and update the `config.json`.  Azurehpc provides the `azhpc-init` command that can help here by copying the directory and substituting the unset variables.  First run with the `-s` parameter to see which variables need to be set:

```
azhpc-init -c $azhpc_dir/examples/slurm_lustre -d slurm_lustre -s
```

The variables can be set with the `-v` option where variables are comma separated.  The output from the previous command as a starting point.  The `-d` option is required and will create a new directory name for you.  Please update to whatever `resource_group` you would like to deploy to:

```
azhpc-init -c $azhpc_dir/examples/slurm_lustre -d slurm_lustre -v resource_group=azurehpc-cluster
```

> Note:  You can still update variables even if they are already set.  For example, in the command below we change the region to `eastus` and the compute node SKU to `Standard_HB120rs_v3`:

```
azhpc-init -c $azhpc_dir/examples/slurm_lustre -d slurm_lustre -v location=eastus,vm_type=Standard_HB120rs_v3,resource_group=azhpc-cluster
```

## Create the cluster 

```
cd slurm_lustre
azhpc-build
```

Allow ~10-15 minutes for deployment.

## Log in the cluster

Connect to the headnode and check SLURM and Lustre are running:

```
$ azhpc connect -u hpcuser headnode
[2021-09-07 13:40:51] logging directly into headnodeb1111b.westeurope.cloudapp.azure.com
[hpcuser@headnode ~]$ sinfo
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
compute*     up   infinite      2   idle compute[000000-000001]
[hpcuser@headnode ~]$ mount|grep lustre
10.2.4.4@tcp:/LustreFS on /lustre type lustre (rw,seclabel,flock,lazystatfs)
hpcuser@compute000000 ~]$ srun hostname
compute000000
compute000001
```

## Using the cluster

Example of using SLURM to run interactive job, check if LFS is mounted on job nodes and run Intel MPI Benchmark:

```
[hpcuser@headnode ~]$ ls /lustre/
[hpcuser@headnode ~]$ touch /lustre/this_is_lustre
[hpcuser@headnode ~]$ salloc -N2 --ntasks-per-node=1
salloc: Granted job allocation 6
[hpcuser@compute000000 ~]$ srun hostname
compute000000
compute000001
[hpcuser@compute000000 ~]$ srun ls /lustre/
this_is_lustre
this_is_lustre
[hpcuser@compute000000 ~]$ module add mpi/impi-2021
Loading mpi version 2021.2.0
[hpcuser@compute000000 ~]$ mpiexec IMB-MPI1 pingpong
#----------------------------------------------------------------
#    Intel(R) MPI Benchmarks 2021.2, MPI-1 part
#----------------------------------------------------------------
# Date                  : Tue Sep  7 12:41:46 2021
# Machine               : x86_64
# System                : Linux
# Release               : 3.10.0-1160.24.1.el7.x86_64
# Version               : #1 SMP Thu Apr 8 19:51:47 UTC 2021
# MPI Version           : 3.1
# MPI Thread Environment:


# Calling sequence was:

# IMB-MPI1 pingpong

# Minimum message length in bytes:   0
# Maximum message length in bytes:   4194304
#
# MPI_Datatype                   :   MPI_BYTE
# MPI_Datatype for reductions    :   MPI_FLOAT
# MPI_Op                         :   MPI_SUM
#
#

# List of Benchmarks to run:

# PingPong

#---------------------------------------------------
# Benchmarking PingPong
# #processes = 2
#---------------------------------------------------
       #bytes #repetitions      t[usec]   Mbytes/sec
            0         1000         1.73         0.00
            1         1000         1.87         0.54
            2         1000         1.73         1.16
            4         1000         1.74         2.31
            8         1000         1.86         4.30
           16         1000         1.74         9.21
           32         1000         1.78        17.94
           64         1000         2.13        30.10
          128         1000         2.07        61.76
          256         1000         2.62        97.63
          512         1000         2.70       189.98
         1024         1000         3.00       341.76
         2048         1000         3.49       586.52
         4096         1000         3.94      1038.63
         8192         1000         5.02      1631.74
        16384         1000         6.84      2395.55
        32768         1000        11.73      2794.52
        65536          640        14.06      4660.99
       131072          320        19.81      6616.03
       262144          160        31.11      8426.69
       524288           80        53.78      9748.70
      1048576           40        98.16     10681.87
      2097152           20       188.48     11126.93
      4194304           10       369.64     11347.01


# All processes entering MPI_Finalize
```
