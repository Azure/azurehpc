## Install and run Darshan (I/O Characterization tool)

## Prerequisites

Cluster is built with the desired configuration for networking, storage, compute etc. You can see the tutorial or examples folder in this repo for how to set this up. Spack is installed (See [here](../spack/readme.md) for details).

Dependencies for binary version:

* None


First copy the apps directory to the cluster in a shared directory.  The `azhpc-scp` can be used to do this:

```
azhpc-scp -r $azhpc_dir/apps/. hpcuser@headnode:.
```

> Alternatively you can checkout the azurehpc repository but you will need to update the paths according to where you put it.


## Connect to the headnode

```
azhpc-connect -u hpcuser headnode
```

## Installation

### Run Darshan-util and Darshan-runtime installation scripts

On head node install Darshan-util
```
apps/darshan/install_darshan_util.sh 
```

On the compute VM's install Darshan-runtime
```
apps/darshan/install_runtime.sh 
```

## Example of Running Darshan to I/O profile an IOR benchmark


Run the following IOR PBS script (In this case darshan used LD_PRELOAD to catch and record I/O) :

```
qsub -l select=2:ncpus=120:mpiprocs=4 -v FILESYSTEM=/lustre apps/darshan/ior_darshan.pbs

```
> Where FILESYSTEM is the location of the filesystem being tested. The environmental variable DARSHAN_LOG_DIR_PATH is the location of the resulting darshan log files. Scripts are provided to create MPI wrappers which will instrument Darshan at compile/link time.

## Generate a Darshan graphical summary report.

On headnode
```
spack load darshan-util
darshan-job-summary.pl $DARSHAN_LOG_DIR_PATH/<Name_of_Darshan_log_file>.darshan
```
A pdf file should be created called <Name_of_Darshan_log_file>.darshan.pdf

You can then view the pdf report with any pdf viewer (e.g evince)

```
evince <Name_of_Darshan_log_file>.darshan.pdf
```
> Note : Make use X-forwarding is enabled.

![Alt text1](/apps/darshan/images/darshan_ior1.JPG?raw=true "ior1")
![Alt text1](/apps/darshan/images/darshan_ior2.JPG?raw=true "ior2")
![Alt text1](/apps/darshan/images/darshan_ior3.JPG?raw=true "ior3")

>Note: You can also generate text reports using the darshan-parser
