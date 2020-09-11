# IO-500 HPC Storage benchmark

The [IO-500](https://www.vi4io.org/std/io500/start) is a I/O storage benchmark designed to measure and compare different HPC storage solutions. It runs a suite of throughput, IOPS and metadata benchmarks and gives a score to rank the storage solution. It uses modified versions of LLNL IOR/MDtest and a find benchmark.

The IO-500 benchmark needs to be built on HB or HC sku's with CentOS-HPC 7.6 (using mpi/mpich-3.3). See one of the examples for building a Cluster with HB or HC skus and PBS. (e.g. [simple_hpc_pbs](../../examples/simple_hpc_pbs/readme.md))


Copy apps dir to the headnode (to access io500 build and run scripts from the headnode)
```
azhpc-scp -r $azhpc_dir/apps hpcuser@headnode:.
```


log-on to the headnode
```
azhpc-connect headnode
```


Build the IO-500 benchmark suite from the build script.  This will install IO-500 into /apps/io500-app and create a modulefile:
```
    build_io500.sh
```

Now submit and run the IO-500 benchmark (e.g on HB selecting /beegfs/datafiles as the filesystem to test):
```
     qsub -l select=2:ncpus=60:mpiprocs=15 -v FILESYSTEM=/beegfs/datafiles io500.pbs
```

> Note: this will run on 2 node and 15 processes per node, testing /beegfs.

The io500 configuration file (i.e config-io500.ini) contains suitable parameters that control which filesystem is measured and the amount of the I/O the benchmark does. Suitable defaults have been choosen. Detailed benchmark output is contained in the results directory.


The result_summary.txt will look like the following (listing all the I/O tests performed and a TOTAL score is computed)
IO500 version io500-isc20_v4
[RESULT]       ior-easy-write        7.732005 GiB/s  : time 323.364 seconds
[RESULT]    mdtest-easy-write       18.238768 kIOPS : time 332.486 seconds
[RESULT]       ior-hard-write        0.112510 GiB/s  : time 6226.295 seconds
[RESULT]    mdtest-hard-write        7.939670 kIOPS : time 323.980 seconds
[RESULT]                 find      152.461045 kIOPS : time 54.535 seconds
[RESULT]        ior-easy-read        2.195966 GiB/s  : time 1138.617 seconds
[RESULT]     mdtest-easy-stat        9.761135 kIOPS : time 596.503 seconds
[RESULT]        ior-hard-read        0.455866 GiB/s  : time 1536.854 seconds
[RESULT]     mdtest-hard-stat        4.353612 kIOPS : time 571.513 seconds
[RESULT]   mdtest-easy-delete        9.167135 kIOPS : time 635.363 seconds
[RESULT]     mdtest-hard-read        5.002237 kIOPS : time 497.290 seconds
[RESULT]   mdtest-hard-delete        2.427297 kIOPS : time 1025.390 seconds
[SCORE] Bandwidth 0.966020 GB/s : IOPS 10.054338 kiops : TOTAL 3.116520```
```
