# OPM installation and running instructions

## Prerequisites

Dependencies for binary version:

* lapack

## Installation 

First copy the apps directory to the cluster.  The `azhpc-scp` can be used to do this:

    azhpc-scp -u hpcuser -r $azhpc_dir/apps hpcuser@headnode:.


> Alternatively you can checkout the azurehpc repository but you will need to update the paths according to where you put it.

### Install from source

For this the headnode needs to be a HC node with CentOS-HPC-7.6 upwards

```
azhpc-run -u hpcuser $azhpc_dir/apps/opm/full_install_opm.sh
```

### Install binaries

```
azhpc-run -u hpcuser $azhpc_dir/apps/opm/install_opm.sh
```

## Connect to the headnode

```
azhpc-connect -u hpcuser headnode
```

## Run the OPM norne scenario
To run on a single node with 30 cores run
```
qsub -l select=1:ncpus=30:mpiprocs=30 $azhpc_dir/apps/opm/flow_norne.sh
```

To run on two node with 30 cores run
```
qsub -l select=2:ncpus=15:mpiprocs=15 $azhpc_dir/apps/opm/flow_norne.sh
```

Notes:
- All job outputs files will be stored in the user home dir with the prefix name OPM_norne.o<job id>.