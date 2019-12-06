## Install and run Pamcrash Benchmarks

## Prerequisites

Cluster is built with the desired configuration for networking, storage, compute etc. You can see the tutorial or examples folder in this repo for how to set this up.

Dependencies for binary version:

* None

## Installation

NOTE: Update the path to the Pamcrash installer tar files in $azhpc_dir/apps/pamcrash/install_pamcrash.sh

First copy the apps directory to the cluster.  The `azhpc-scp` can be used to do this:

```
azhpc-scp -u hpcuser -r $azhpc_dir/apps hpcuser@headnode:.
```

> Alternatively you can checkout the azurehpc repository but you will need to update the paths according to where you put it.

```
azhpc-run -u hpcuser  apps/pamcrash/install_pamcrash.sh 
```

> Note: This will install into `/apps`.

## Connect to the headnode

```
azhpc-connect -u hpcuser headnode
```

## Running

NOTE: In the run script you will need to update the license server.  Currently it is set to localhost which would require a tunnel to be created (currently the ssh tunnel command commented out in the script).

Copy the pamcrash input model to working directory.

Now, you can run as follows:

```
qsub -l select=${nodes}:ncpus=${ppn}:mpiprocs=${ppn} -N $name ./run_impi.sh
```
