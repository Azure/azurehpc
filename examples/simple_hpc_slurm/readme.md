# Build a SLURM  cluster

Visualisation: [config.json](https://azurehpc.azureedge.net/?o=https://raw.githubusercontent.com/Azure/azurehpc/master/examples/simple_hpc_slurm/config.json)

This example will create an HPC cluster ready to run with SLURM.

## Initialise the project

To start you need to copy this directory and update the `config.json`.  Azurehpc provides the `azhpc-init` command that can help here by copying the directory and substituting the unset variables.  First run with the `-s` parameter to see which variables need to be set:

```
azhpc-init -c $azhpc_dir/examples/simple_hpc_slurm -d simple_hpc_slurm -s
```

The variables can be set with the `-v` option where variables are comma separated.  The output from the previous command as a starting point.  The `-d` option is required and will create a new directory name for you.  Please update to whatever `resource_group` you would like to deploy to:

```
azhpc-init -c $azhpc_dir/examples/simple_hpc_slurm -d simple_hpc_slurm -v resource_group=azurehpc-cluster
```

> Note:  You can still update variables even if they are already set.  For example, in the command below we change the region to `westus2` and the SKU to `Standard_HC44rs`:

```
azhpc-init -c $azhpc_dir/examples/simple_hpc_slurm -d simple_hpc_slurm -v location=westus2,vm_type=Standard_HC44rs,resource_group=azhpc-cluster
```

## Create the cluster 

```
cd simple_hpc_slurm
azhpc-build
```

Allow ~10 minutes for deployment.  You are able to view the status VMs being deployed by running `azhpc-status` in another terminal.

## Log in the cluster

Connect to the headnode and check SLURM and NFS

```
$ azhpc connect -u hpcuser headnode
[2021-07-09 17:55:37] logging directly into headnode14234.westeurope.cloudapp.azure.com
[hpcuser@headnode ~]$ sinfo -Nel
Fri Jul 09 16:55:43 2021
NODELIST       NODES PARTITION       STATE CPUS    S:C:T MEMORY TMP_DISK WEIGHT AVAIL_FE REASON              
compute000000      1  compute*        idle 44     2:22:1 354545        0      1   (null) none                
compute000003      1  compute*        idle 44     2:22:1 354545        0      1   (null) none                
[hpcuser@headnode ~]$ sinfo
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
compute*     up   infinite      2   idle compute[000000,000003]
[hpcuser@headnode ~]$ sudo exportfs -v
/share/apps     <world>(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,no_root_squash,no_all_squash)
/share/data     <world>(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,no_root_squash,no_all_squash)
/share/home     <world>(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,no_root_squash,no_all_squash)
/mnt/resource/scratch
                <world>(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,no_root_squash,no_all_squash)
```

To check the state of the cluster you can run the following commands

```
azhpc-connect -u hpcuser headnode
squeue
sinfo
sinfo -Nel
df -h
```
## Using the cluster

Example of using SLURM for interactive job running Intel MPI Benchmark:

```
[hpcuser@headnode ~]$ module add mpi/impi
[hpcuser@headnode ~]$ salloc -N2 -n2
salloc: Granted job allocation 6
[hpcuser@compute000000 ~]$ which mpiexec
/opt/intel/compilers_and_libraries_2018.5.274/linux/mpi/intel64/bin/mpiexec
[hpcuser@compute000000 ~]$ mpiexec hostname
compute000000
compute000003
[hpcuser@compute000000 ~]$ mpiexec IMB-MPI1 pingpong
#------------------------------------------------------------
#    Intel (R) MPI Benchmarks 2018, MPI-1 part    
#------------------------------------------------------------
# Date                  : Fri Jul  9 17:17:01 2021
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
            0         1000         1.97         0.00
            1         1000         1.97         0.51
            2         1000         2.07         0.97
            4         1000         1.96         2.04
            8         1000         1.96         4.09
           16         1000         2.07         7.71
           32         1000         2.85        11.22
           64         1000         2.84        22.54
          128         1000         2.90        44.20
          256         1000         3.04        84.07
          512         1000         3.10       164.92
         1024         1000         3.30       310.49
         2048         1000         3.72       550.23
         4096         1000         4.39       932.50
         8192         1000         5.90      1387.66
        16384         1000         7.86      2083.70
        32768         1000        10.65      3076.66
        65536          640        15.48      4232.81
       131072          320        23.73      5523.54
       262144          160       299.18       876.21
       524288           80       702.23       746.61
      1048576           40       771.87      1358.48
      2097152           20       902.10      2324.73
      4194304           10      1156.95      3625.31


# All processes entering MPI_Finalize
```
