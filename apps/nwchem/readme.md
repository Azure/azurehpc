# NWCHEM installation and running instructions

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

## Run the NWCHEM h2o_freq scenario
To run on a single node with 4 cores run
```
qsub -l select=1:ncpus=120:mpiprocs=4 -v INPUTDIR=/data/nwchm run_nwchem.pbs
```

To run on two HBv2 nodes with 8 total cores (4 cores on each node) run
```
qsub -l select=2:ncpus=120:mpiprocs=4 -v INPUTDIR=/data/nwchm run_nwchem.pbs
```

## Install and run nwchem Benchmarks using [Azure CycleCloud](https://docs.microsoft.com/en-us/azure/cyclecloud/) Cluster 

## Prerequisites

These steps require a Azure CycleCloud cluster with PBS.  The `cyclecloud_simple_pbs` template in the examples directory a suitable choice.

Follow the steps in the examples/cyclecloud_simple_pbs/readme.md to setup cycle, import the template and start cluster.

Log in to the headnode of the cluster (from cycleserver):

```
    $ cyclecloud connect master -c <cyclecloud cluster name>
```

## Installing nwchem

You will need to copy the apps/nwchem folder to the cyclecloud master.

Run the following to install nwchem on the cluster (in /scratch):

export APP_INSTALL_DIR=/scratch
```
apps/nwchem/build_install_nwchem.sh
```

## Running nwchem

Copy apps/nwchem to the cyclecloud master node.

To run on two HBv2 nodes with 8 total cores (4 cores on each node) run (nwchem installation and model are in /scratch)
```
qsub -l select=2:ncpus=120:mpiprocs=4 -v APP_INSTALL_DIR=/scratch,INPUTDIR=/scratch/nwchem run_nwchem.pbs
```
