## Install and run abaqus Benchmarks using azurehpc cluster

## Prerequisites

Cluster is built with the desired configuration for networking, storage, compute etc. You can see the tutorial or examples folder in this repo for how to set this up.

Dependencies for binary version:

* None

NOTE: Update the license server for abaqus in $azhpc_dir/apps/abaqus/install_abaqus.sh

First copy the apps directory to the cluster.  The `azhpc-scp` can be used to do this:

```
azhpc-scp -r $azhpc_dir/apps hpcuser@headnode:.
```

> Alternatively you can checkout the azurehpc repository but you will need to update the paths according to where you put it.

## Installation

You must first obtain the abaqus installer tar files and copy it to the cluster - 2019.AM_SIM_Abaqus_Extend.AllOS.1-5.tar, 2019.AM_SIM_Abaqus_Extend.AllOS.2-5.tar, 2019.AM_SIM_Abaqus_Extend.AllOS.3-5.tar, 2019.AM_SIM_Abaqus_Extend.AllOS.4-5.tar, 2019.AM_SIM_Abaqus_Extend.AllOS.5-5.tar

```
azhpc-scp -r 2019.AM_SIM_Abaqus_Extend.AllOS.*-5.tar hpcuser@headnode:/mnt/resource/.
```

The following environment variables can be used:

| Environment Variable  | Default Value | Description                                                                       |
|------------------------|--------------------------------------------------------------------|-----------------------------------------------------------------------------------------|
| ABAQUS_INSTALLER_DIR   | /mnt/resource                                                      | The path to the '2019.AM_SIM_Abaqus_Extend.AllOS.*-5.tar' installer files     |
| LICENSE_SERVER_IP      |                                                                    | License server ip address

```
azhpc-run -u hpcuser apps/abaqus/install_abaqus.sh 

```

> Note: This will install into `/apps`.

Next, copy the <model>.inp file to the headnode under /data

```
azhpc-scp -r <model>.inp hpcuser@headnode:/data/.
```

## Connect to the headnode

```
azhpc-connect -u hpcuser headnode
```

## Running

NOTE: Update the license server in $azhpc_dir/apps/abaqus/run_abaqus_intelmpi.pbs

The following environment variables can be used:

| Environment Variable   | Default Value | Description                                                                             |
|------------------------|---------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------|
| APP_INSTALL_DIR        | /apps         | The place where abaqus is installed                                                     |
| DATA_DIR               | /data         | The directory where the inp file is located (relative paths are based on PBS_O_WORKDIR) |
| MODEL                  | e1            | The model to use                                  									   |
| LICENSE_SERVER_IP      |               | License server ip address

Now, you can run as follows:

```
qsub -l select=2:ncpus=15:mpiprocs=15,place=scatter:excl apps/abaqus/run_abaqus_intelmpi.pbs
```
Note: You can pass variables to the script by using -v for e.g. -v "MODEL=<model name>" 

## Install and run abaqus Benchmarks using CycleCloud cluster

## Prerequisites

These steps require a Azure CycleCloud cluster with PBS.  The `cyclecloud_simple_pbs` template in the examples directory a suitable choice. 

NOTE: Update the license server for abaqus in $azhpc_dir/apps/abaqus/install_abaqus.sh

First copy the $azhpc_dir/apps directory to the /mnt/resource.  


> Alternatively you can checkout the azurehpc repository but you will need to update the paths according to where you put it.

## Connect to the headnode

```
    $ cyclecloud connect master -c abaqus
```

## Installation

You must first obtain the abaqus installer tar files and copy it to the cluster - 2019.AM_SIM_Abaqus_Extend.AllOS.1-5.tar, 2019.AM_SIM_Abaqus_Extend.AllOS.2-5.tar, 2019.AM_SIM_Abaqus_Extend.AllOS.3-5.tar, 2019.AM_SIM_Abaqus_Extend.AllOS.4-5.tar, 2019.AM_SIM_Abaqus_Extend.AllOS.5-5.tar under /mnt/resource

The following environment variables can be used:

| Environment Variable   | Default Value | Description                                        |
|------------------------|--------------------------------------------------------------------|-----------------------------------------------------------------------------------------|
| APP_INSTALL_DIR        | /scratch                                                           | The place to install (a a directory will be created here                      |
| ABAQUS_INSTALLER_DIR   | /mnt/resource                                                      | The path to the '2019.AM_SIM_Abaqus_Extend.AllOS.*-5.tar' installer files     |
| LICENSE_SERVER         |                                                                    | License server ip address

```
export APP_INSTALL_DIR=/scratch
apps/abaqus/install_abaqus.sh 

```

> Note: This will install into `/apps`.

## Running

The model will need to be copied to the cluster. The default model is e1. You can copy the inp file to the headnode under /scratch.

NOTE: Update the license server in $azhpc_dir/apps/abaqus/run_abaqus_intelmpi.pbs

Now, you can run as follows:

```
qsub -v "MODEL=<model name>" -l select=2:ncpus=15:mpiprocs=15,place=scatter:excl apps/abaqus/run_abaqus_intelmpi.pbs

```
