# NWCHEM installation and running instructions

## Prerequisites

Dependencies for binary version:

* None

## Installation 

First copy the apps directory to the cluster.  The `azhpc-scp` can be used to do this:

    azhpc-scp -r $azhpc_dir/apps hpcuser@headnode:.


> Alternatively you can checkout the azurehpc repository but you will need to update the paths according to where you put it.

### Install from source

For this the headnode needs to be a HB or HC node with CentOS-HPC-7.6 upwards

```
azhpc-run -u hpcuser apps/nwchem/build_install_nwchem.sh
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
qsub -l select=1:ncpus=60:mpiprocs=4 $HOME/apps/nwchem/run_h2o_freq.sh
```

To run on two HB nodes with 8 total cores (4 cores on each node) run
```
qsub -l select=2:ncpus=60:mpiprocs=4 $azhpc_dir/apps/nwchem/run_h2o_freq.sh
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

To run on two HB nodes with 8 total cores (4 cores on each node) run (nwchem installation and model are in /scratch)
```
qsub -l select=2:ncpus=60:mpiprocs=4 -v APP_INSTALL_DIR=/scratch,DATA_DIR=/scratch apps/nwchem/run_h2o_freq.sh
```
