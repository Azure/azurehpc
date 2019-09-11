# IOR and mdtest

This requires ior to be built on HB or HC sku's with CentOS-HPC 7.6 (using mpi/mpich-3.3)

First build IOR from the build script.  This will install ior/mdtest in /apps/ior and create a modulefile:

    build_ior.sh

Now submit and run (e.g on HB):

     qsub -l select=2:ncpus=60:mpiprocs=15 ior.pbs

> Note: this will run on 2 node and 15 processes per node.

The ior.pbs script runs a throughput (N-N and N-1) and IOPS test.

A metadata I/O benchmark test can be run using the mdtest.pbs script.

      qsub -l select=2:ncpus=60:mpiprocs=15 mdtest.pbs
