# NWCHEM installation and running instructions

## Prerequisites

Dependencies for binary version:

* None

## Installation 

First copy the apps directory to the cluster.  The `azhpc-scp` can be used to do this:

    azhpc-scp -r $azhpc_dir/apps hpcuser@headnode:.


> Alternatively you can checkout the azurehpc repository but you will need to update the paths according to where you put it.

### Install from source

For this the headnode needs to be a HC node with CentOS-HPC-7.6 upwards

```
azhpc-run -u hpcuser $azhpc_dir/apps/nwchem/build_install_nwchem.sh
```

### Install binaries

None

## Connect to the headnode

```
azhpc-connect -u hpcuser headnode
```

## Run the NWCHEM h2o_freq scenario
To run on a single node with 4 cores run
```
qsub -l select=1:ncpus=4:mpiprocs=4 $azhpc_dir/apps/nwchem/run_h2o_freq.sh
```

To run on two HB nodes with 8 total cores (4 cores on each node) run
```
qsub -l select=2:ncpus=60:mpiprocs=4 $azhpc_dir/apps/nwchem/run_h2o_freq.sh
```
