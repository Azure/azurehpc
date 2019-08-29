## Install and run LAMMPS Benchmarks

## Prerequisites

Cluster is built with the desired configuration for networking, storage, compute etc. You can see the tutorial or examples folder in this repo for how to set this up.

Dependencies for binary version:

* None

NOTE: Update the path to the lammps installer storageendpoint, sasurl and license server in $azhpc_dir/apps/lammps/install_lammps.sh

First copy the apps directory to the cluster in a shared directory.  The `azhpc-scp` can be used to do this:

```
azhpc-scp -u hpcuser -r $azhpc_dir/apps/. hpcuser@headnode:/apps
```

> Alternatively you can checkout the azurehpc repository but you will need to update the paths according to where you put it.

## Installation

```
azhpc-run -u hpcuser -n "headnode compute" /apps/lammps/install_lammps.sh  

```

## Connect to the headnode

```
azhpc-connect -u hpcuser headnode
```

## Running

NOTE: Update the path to the lammps benchmark storageendpoint, saskey and license server in $azhpc_dir/apps/lammps/run_lammps_intelmpi.sh

Now, you can run as follows:

```
qsub -l select=2:ncpus=15:mpiprocs=15,place=scatter:excl /apps/lammps/run_lammps_intelmpi.sh

```
