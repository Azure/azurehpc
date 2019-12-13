## Install and run WRF v4 and WPS v4

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

### Run wrf install script
```
apps/wrf/install_wrf.sh 
```

Run the WPS installation script if you need to install WPS (WRF needs to be installed first)
```
apps/wrf/install_wps.sh 
```

## Running


Now, you can run wrf as follows:

```
qsub -l select=2:ncpus=60:mpiprocs=15 -v INPUTDIR=/path/to/inputfiles apps/wrf/run_wrf.pbs

```
Where INPUTDIR contains the location of wrf input files (namelist.input, wrfbdy_d01 and wrfinput_d01)
