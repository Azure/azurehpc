# Quantum Espresso installation and running instructions

## Prerequisites

Cluster is built with the desired configuration for networking, storage, compute etc. You can see the tutorial or examples folder in this repo for how to set this up. Spack is installed (See [here](../spack/readme.md) for details).

## Installation 

First copy the apps directory to the cluster.  The `azhpc-scp` can be used to do this:

    azhpc-scp -r $azhpc_dir/apps hpcuser@headnode:.


> Alternatively you can checkout the azurehpc repository but you will need to update the paths according to where you put it.

### Install from source

For this the headnode needs to be a HBv2, HB or HC node with CentOS-HPC-7.7 upwards (or install on a compute node)

```
azhpc-run -u hpcuser $azhpc_dir/apps/nwchem/build_install_nwchem.sh
```

### Install binaries

None

## Connect to the headnode

```
azhpc-connect -u hpcuser headnode
```

## Run Quantum Espresso
To run on two HBv2 nodes with 8 total cores (4 cores on each node) run
```
qsub -l select=2:ncpus=120:mpiprocs=4 -v INPUTDIR=/data/nwchm,EXE_NAME=pw.x run_nwchem.pbs
```
>Note: By default the pw.x executable will be selected, set the variable EXE_NAME to a different executable if desired. The input files located in directory identified by variable INPUTDIR will be copied to the current working directory. 

