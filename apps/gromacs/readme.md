## Install and run gromacs Benchmarks

## Prerequisites

Cluster is built with the desired configuration for networking, storage, compute etc. You can see the tutorial or examples folder in this repo for how to set this up.

Dependencies for binary version:

* None

## Installation

NOTE: Update the gromacs version if needed in $azhpc_dir/apps/gromacs/install_gromacs.sh

First copy the apps directory to the cluster.  The `azhpc-scp` can be used to do this:

```
azhpc-scp -u hpcuser -r $azhpc_dir/apps hpcuser@headnode:.
```

> Alternatively you can checkout the azurehpc repository but you will need to update the paths according to where you put it.

```
azhpc-run -u hpcuser  apps/gromacs/install_gromacs.sh 
```

> Note: This will install into `/apps`.

## Connect to the headnode

```
azhpc-connect -u hpcuser headnode
```

## Running

NOTE: Update the gromacs version in $azhpc_dir/apps/gromacs/run_intelmpi.sh if needed

Now, you can run as follows:

```
qsub -v "package=<benchmark tar name>","casename=<casename>" -l select=2:ncpus=15:mpiprocs=30:ompthreads=1,place=scatter:excl apps/gromacs/run_intelmpi.sh

e.g. "package=GROMACS_TestCaseA.tar.gz","casename=ion_channel.tpr" 
		OR
	 "package=GROMACS_TestCaseB.tar.gz","casename=lignocellulose-tf.tpr" 


```
