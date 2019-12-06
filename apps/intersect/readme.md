# Intersect installation and running instructions

## Prerequisites

Cluster is built with the desired configuration for networking, storage, compute etc. You can see the tutorial or examples folder in this repo for how to set this up.

Dependencies for binary version:

None

Edit intersect full_intersect_2018.2.sh to have the license server and port number, sas url for intersect and eclipse iso 
Where PORT and IP are port and IP address of license server (e.g 23456@17.20.20.1)

Edit install_case_intersect_2018.2.sh to update sas url for the dataset tar file 

# Install applications

First copy the apps directory to the cluster.  The `azhpc-scp` can be used to do this:

```
azhpc-scp -r $azhpc_dir/apps hpcuser@headnode:.
```

> Alternatively you can checkout the azurehpc repository but you will need to update the paths to apps directory according to where you put it.

If you plan on running intersect, you will be required to set-up your own licensing. Intersect will need a valid PORT@IP to your license
server.


# Intersect installation and running instructions

## Install Intersect and eclipse from iso files

```
azhpc-run -u hpcuser apps/intersect/install_full_intersect_2018.2.sh
```

## Install the data sets for intersect

````
azhpc-run -a apps/intersect/install_case_intersect_2018.2.sh
````

## Run Intersect

Intersect is run from the headnode (as user hpcuser), First log-in to headnode as user hpcuser.
```
azhpc-connect -u hpcuser headnode
```

Next run

```
qsub -v "casename=<case name>" -l select=2:ncpus=15:mpiprocs=15,place=scatter:excl /apps/intersect/run_intersect_2018.2.sh 
```

Where "case name" (e.g BO_192_192_28) is the intersect case you want to run)

To see if the job is running do
````
qstat -aw
````

## Install and run intersect Benchmarks using [Azure CycleCloud](https://docs.microsoft.com/en-us/azure/cyclecloud/) Cluster

## Prerequisites

These steps require a Azure CycleCloud cluster with PBS.  The `cyclecloud_simple_pbs` template in the examples directory a suitable choice.

Follow the steps in the examples/cyclecloud_simple_pbs/readme.md to setup cycle, import the template and start cluster.

Log in to the headnode of the cluster (from cycleserver):

```
    $ cyclecloud connect master -c <cyclecloud cluster name>
```

## Installing Intersect

You will need to copy the apps/intersect folder to the cyclecloud master.

Run the following to install ntersect on the cluster (in /scratch):

export APP_INSTALL_DIR=/scratch
```
apps/intersect/install_full_intersect_2018.2.sh
```

## Install the data sets for intersect

export DATA_INSTALL_DIR=/scratch
```
apps/intersect/install_case_intersect_2018.2.sh
```

## Running Intersect

Copy apps/intersect to the cyclecloud master node.

To run on two HB nodes with 8 total cores (4 cores on each node) run ( Intersect installation and case model are in /scratch)
```
qsub -l select=2:ncpus=60:mpiprocs=4 -v case=BO_192_192_28,APP_INSTALL_DIR=/scratch,DATA_INSTALL_DIR=/scratch apps/intersect/run_intersect_2018.2.sh
```
