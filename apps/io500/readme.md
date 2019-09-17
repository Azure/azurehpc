# IO-500 HPC Storage benchmark

The [IO-500](https://www.vi4io.org/std/io500/start) is a I/O storage benchmark designed to measure and compare different storage solutions. It runs a suite of throughput, IOPS and metadata benchmarks and gives a score to rank the storage solution. It uses modified versions of LLNL IOR/MDtest and a find benchmark.

This requires IO-500 to be built on HB or HC sku's with CentOS-HPC 7.6 (using mpi/mpich-3.3). See one of the examples for building a Cluster with HB or HC skus and PBS. (e.g. [simple_hpc_pbs](../../examples/simple_hpc_pbs/readme.md))

log-on to the headnode
```
azhpc-connect headnode
```

Build the IO-500 benchmark suite from the build script.  This will install IO-500 into /apps/io-500-dev and create a modulefile:
```
    build_io500.sh
```

Now submit and run the IO-500 benchmark (e.g on HB):
```
     qsub -l select=2:ncpus=60:mpiprocs=15 io500.pbs
```

> Note: this will run on 2 node and 15 processes per node.

There are a number of parameters in the io500.pbs script that control which filesystem is measured and the amount of the I/O the benchmark does.
