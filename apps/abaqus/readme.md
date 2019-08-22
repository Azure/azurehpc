## Install and run abaqus Benchmarks

## Prerequisites

Cluster is built with the desired configuration for networking, storage, compute etc. You can see the tutorial or examples folder in this repo for how to set this up.

Dependencies for binary version:

* None

NOTE: Update the path to the abaqus installer storageendpoint, sasurl and license server in $azhpc_dir/apps/abaqus/install_abaqus.sh

First copy the apps directory to the cluster.  The `azhpc-scp` can be used to do this:

```
azhpc-scp -u hpcuser -r $azhpc_dir/apps hpcuser@headnode:.
```

> Alternatively you can checkout the azurehpc repository but you will need to update the paths according to where you put it.

## Connect to the headnode

```
azhpc-connect -u hpcuser headnode
```

## Installation

```
apps/abaqus/install_abaqus.sh 

```

> Note: This will install into `/apps`.

## Running

NOTE: Update the path to the abaqus benchmark storageendpoint, saskey and license server in $azhpc_dir/apps/abaqus/run_intelmpi.sh

Now, you can run as follows:

```
qsub -v "MODEL=<model name>" -l select=2:ncpus=15:mpiprocs=15,place=scatter:excl apps/abaqus/run_abaqus_intelmpi.pbs

```
