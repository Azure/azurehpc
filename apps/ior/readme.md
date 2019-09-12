# IOR and mdtest

This requires ior to be built on HB or HC sku's with CentOS-HPC 7.6 (using mpi/mpich-3.3). See one of the examples for building a Cluster with HB or HC skus and PBS. (e.g. [simple_hpc_pbs](../../examples/simple_hpc_pbs/readme.md))

log-on to the headnode
```
azhpc-connect headnode
```

Build IOR/mdtest from the build script.  This will install ior and mdtest into /apps/ior and create a modulefile:
```
    build_ior.sh
```

Now submit and run (e.g on HB):
```
     qsub -l select=2:ncpus=60:mpiprocs=15 ior.pbs
```

> Note: this will run on 2 node and 15 processes per node.

The ior.pbs script runs a throughput (N-N and N-1) and IOPS test.

A metadata I/O benchmark test can be run using the mdtest.pbs script.
```
      qsub -l select=2:ncpus=60:mpiprocs=15 mdtest.pbs
```
