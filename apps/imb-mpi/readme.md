# IMB-MPI benchmarks

The following PBS scripts are available to run the IMB-MPI1 benchmarks:

* ringpingpong.pbs
* allreduce.pbs

The ringpingpong will report the ping pong times between adjacent nodes in the hostlist.  A separate file is output for each run but the 1024 byte results will be displayed in a table sorted from best to worst.  Here is an example of how to run:

    qsub -l select=8:ncpus=1:mpiprocs=1,place=scatter:excl ringpingpong.pbs

The allreduce will perform the 8 and 16 byte all reduce with all the cores for the job.  Run as follows:

    qsub -l select=8:ncpus=60:mpiprocs=60,place=scatter:excl allreduce.pbs

