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


Build the IO-500 benchmark suite from the build script.  This will install IO-500 into /apps/io-500-dev and create a modulefile:
```
    build_io500.sh
```

Now submit and run the IO-500 benchmark (e.g on HB selecting /beegfs as the filesystem to test):
```
     qsub -l select=2:ncpus=60:mpiprocs=15 -v FILESYSTEM=/beegfs io500.pbs
```

> Note: this will run on 2 node and 15 processes per node, testing /beegfs.

There are a number of parameters in the io500.pbs script that control which filesystem is measured and the amount of the I/O the benchmark does. Suitable defaults have been choosen. Detailed benchmark output is contained in the results directory.


The tail end of a results summary file will look like the following (listing all the I/O tests performed and a TOTAL score is computed)
```
[Summary] Results files in /beegfs/io500/results/2019.09.17-22.52.53
[Summary] Data files in /beegfs/datafiles/io500.2019.09.17-22.52.53
[RESULT] BW   phase 1            ior_easy_write                8.581 GB/s : time  58.27 seconds
[RESULT] BW   phase 2            ior_hard_write                0.237 GB/s : time 708.39 seconds
[RESULT] BW   phase 3             ior_easy_read                2.449 GB/s : time 204.18 seconds
[RESULT] BW   phase 4             ior_hard_read                1.378 GB/s : time 122.00 seconds
[RESULT] IOPS phase 1         mdtest_easy_write               20.608 kiops : time 333.32 seconds
[RESULT] IOPS phase 2         mdtest_hard_write                1.862 kiops : time 330.43 seconds
[RESULT] IOPS phase 3                      find              305.930 kiops : time  24.64 seconds
[RESULT] IOPS phase 4          mdtest_easy_stat               80.907 kiops : time  84.90 seconds
[RESULT] IOPS phase 5          mdtest_hard_stat                5.686 kiops : time 108.18 seconds
[RESULT] IOPS phase 6        mdtest_easy_delete               35.207 kiops : time 195.11 seconds
[RESULT] IOPS phase 7          mdtest_hard_read                4.803 kiops : time 128.09 seconds
[RESULT] IOPS phase 8        mdtest_hard_delete                2.625 kiops : time 243.19 seconds
One or more test phases invalid.  Not valid for IO-500 submission.
[SCORE-valid] Bandwidth 1.61907 GB/s : IOPS 14.8749 kiops : TOTAL 4.90749
```
