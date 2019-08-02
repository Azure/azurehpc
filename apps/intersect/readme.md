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
azhpc-scp -u hpcuser -r $azhpc_dir/apps hpcuser@headnode:.
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
