# IOR

This requires the `mpich` package to be installed on the VMs which run.

First build IOR from the build script.  This will put it in `/lustre/ior.exe`:

    build_ior.sh

Now submit and run:

     qsub -l select=4:ncpus=1:mpiprocs=16,place=scatter:excl ior.pbs

> Note: this will run on 4 node and 16 processes per node.

