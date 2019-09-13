# FIO

Fio is a general I/O benchmark code, it has many options to configure and customize the I/O pattern being tested.

To build a cluster with PBS, see one of the examples, e.g. [simple_hpc_pbs](../../examples/simple_hpc_pbs/readme.md)

First log-in to the headnode.
```
    azhpc-connect headnode
```

Build fio from the build script.  This will build and install it in `/apps/fio` and create a module file.

```
    build_fio.sh
```

Now submit and run:

```
     qsub -l select=1:ncpus=60:mpiprocs=8 fio.pbs
```
> Note: this will run on 1 node, 8 fio processes (fio numjobs). Fio can run on multiple nodes in a client-server mode, this example is designed to run on a single node. You can change the fio numjobs parameter (i.e number of processes) by changing the PBS mpiprocs value. A throughput and IOPS benchmark will be run.


A similar script is provided to run the same fio benchmark (throguhput and IOPS) on a Windows client.

A Windows fio executable can be downloaded from
```
    https://bsdio.com/fio/
```

Run the Windows_fio.ps1 powershell script from a Windows powershell prompt.
```
    windows_fio.ps1
```
> Note: You may need to modify the DIRECTORY and ALLJOBS variables in the windows_fio.ps1 script to reflect the location of the drive you want to test and the number of jobs wou want to run on the windows client.

