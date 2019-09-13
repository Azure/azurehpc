# OpenMPI
This is to build OpenMPI with C++ bindings. Not that C++ bindings are not built by default and may be required by some applications.
Run this on an HC or HB node
Before running it make sure that the /apps/modulefiles is writable by hpcuser


## build_4.0_cxx
This will download source from open-mpi.org and create a module file named openmpi-4.0.1 in /apps/modulefiles

## build_hpcx_cxx
This will use the source code from the local HPCX directory and create a module file named hpcx-2.4.1 in /apps/modulefiles

