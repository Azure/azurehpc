# Testing with IMB-MPI1

This example shows how to create and test a cluster.  First take the simple_hpc example to start with so move to your working directory for projects and run:

```
azhpc-init -c $azhpc/examples/simple_hpc -d simplehpc \
    -v resource_group=azurehpc-simplehpc,location=eastus
cd simplehpc
```

We'll be running some performance tests so we can create more nodes by editing `resources.compute.instances` in `config.json`.  Build the cluster with:

    azhpc-build

While it is building you can watch the progress of the provisioning with in another shell with:

    azhpc-watch -u 5

Once the cluster is created copy the apps directory into the `hpcuser` home:

    azhpc-scp -u hpcuser $azhpc_dir/apps hpcuser@headnode:.

The rest of this will run as hpcuser from the headnode in the cluster.  Connect as follows:

    azhpc-connect -u hpcuser headnode

## Ring ping pong

A ring ping pong test is provided to check the IB connection.  This will run a ping pong between all adjacent nodes in the hostlist.  The script provided will extract the 1024 byte result and sort it in order from fastest to slowest.  Any significant outliers here should be excluded from runs.

Here is an example of running:

```
qsub -l select=32:ncpus=1:mpiprocs=1,place=scatter:excl $HOME/apps/imb-mpi/ringpingpong.pbs
```

Wait until the job completes and check the output file.  Here is an example from a 32 node run:
```
$ cat ringpingpong.pbs.o1
Ring Ping Pong Results (1024 bytes)
Source               Destination          Time [usec]
10.2.4.32            10.2.4.36                  2.65
10.2.4.31            10.2.4.32                  2.66
10.2.4.15            10.2.4.16                  2.70
10.2.4.12            10.2.4.13                  2.82
10.2.4.37            10.2.4.38                  2.82
10.2.4.42            10.2.4.5                   2.83
10.2.4.41            10.2.4.42                  2.84
10.2.4.30            10.2.4.31                  2.85
10.2.4.40            10.2.4.41                  2.86
10.2.4.39            10.2.4.4                   2.87
10.2.4.18            10.2.4.19                  2.88
10.2.4.24            10.2.4.26                  2.88
10.2.4.38            10.2.4.39                  2.88
10.2.4.36            10.2.4.37                  2.91
10.2.4.19            10.2.4.20                  2.92
10.2.4.4             10.2.4.40                  2.93
10.2.4.23            10.2.4.24                  2.94
10.2.4.14            10.2.4.15                  2.96
10.2.4.5             10.2.4.6                   2.96
10.2.4.6             10.2.4.7                   2.96
10.2.4.7             10.2.4.8                   2.98
10.2.4.16            10.2.4.18                  3.02
10.2.4.10            10.2.4.11                  3.04
10.2.4.28            10.2.4.29                  3.06
10.2.4.8             10.2.4.10                  3.07
10.2.4.27            10.2.4.28                  3.11
10.2.4.22            10.2.4.23                  3.13
10.2.4.13            10.2.4.14                  3.15
10.2.4.29            10.2.4.30                  3.17
10.2.4.20            10.2.4.22                  3.18
10.2.4.11            10.2.4.12                  3.21
10.2.4.26            10.2.4.27                  3.23
```

All nodes are fairly consistent here.

## Allreduce

The `MPI_Allreduce` on 8 or 16 byte messages is often the bottleneck for HPC applications.  A script is provided to test this.

```
qsub -l select=32:ncpus=44:mpiprocs=44,place=scatter:excl $HOME/apps/imb-mpi/allreduce.pbs
```

Here are the timings at the end of the PBS output once it has run:

```
#----------------------------------------------------------------
# Benchmarking Allreduce
# #processes = 1408
#----------------------------------------------------------------
       #bytes #repetitions  t_min[usec]  t_max[usec]  t_avg[usec]
            0        10000         0.13         0.41         0.16
            8        10000        24.06        30.77        27.94
           16        10000        26.13        29.28        27.28
```

### Checking the impact of the Linux Azure Agent

Running this benchmark for all cores on a VM is very susceptible to any "jitter" from processes running.  We can see how much of an effect the Linux Azure Agent has here.  First stop the agent on all the compute nodes.  This step is run from when the cluster is deployed:

    azhpc-run -n compute sudo systemctl stop waagent

> Note: alternative options to run here would be to use PBS or `pssh`.

Now run again:

```
qsub -l select=32:ncpus=44:mpiprocs=44,place=scatter:excl \
    $HOME/apps/imb-mpi/allreduce.pbs
```

We can compare the results as the performance difference can be seen at this scale:

```
#----------------------------------------------------------------
# Benchmarking Allreduce
# #processes = 1408
#----------------------------------------------------------------
       #bytes #repetitions  t_min[usec]  t_max[usec]  t_avg[usec]
            0        10000         0.13         0.57         0.16
            8        10000        18.24        21.05        19.56
           16        10000        18.52        20.74        19.43      
```
