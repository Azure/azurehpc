## Install and run Fluent Benchmarks

## Prerequisites

Cluster is built with the desired configuration for networking, storage, compute etc. You can see the tutorial or examples folder in this repo for how to set this up.

Dependencies for binary version:

* None

## Installation

NOTE: Update the path to the fluent installer tar file in $azhpc_dir/apps/fluent/install_fluent.sh

First copy the apps directory to the cluster.  The `azhpc-scp` can be used to do this:

```
azhpc-scp -r $azhpc_dir/apps hpcuser@headnode:.
```

> Alternatively you can checkout the azurehpc repository but you will need to update the paths according to where you put it.

```
azhpc-run -u hpcuser  apps/fluent/install_fluent.sh 
```

> Note: This will install into `/apps`.

## Connect to the headnode

```
azhpc-connect -u hpcuser headnode
```

## Setup the benchmark files

Copy the benchmark tarball to /apps/ansys_inc/v193/fluent then run

```
tar xvf <tarfilename>.tar
```

This will place the required files where fluent will find them

## Running

NOTE: In the run script (run_fluent_hpcx.sh) you will need to update the license server.  Currently it is set to localhost which would require a tunnel to be created (currently the ssh tunnel command commented out in the script).


Now, you can run as follows:

```
for ppn in 60 45 30; do
    for nodes in 2 4 8 16 32 64 128; do
        name=racecar_hpcx_${nodes}x${ppn}
        mkdir $name
        cd $name
        cp ../run_fluent_hpcx.sh .
        qsub -l select=${nodes}:ncpus=${ppn}:mpiprocs=${ppn},place=scatter:excl -N $name ./run_fluent_hpcx.sh
        cd -
    done
done
```
