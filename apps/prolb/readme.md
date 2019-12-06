## Install and run PROLB

> Note : This version has been tested on HC44rs and HB60rs. When running on other SKUs, please update the `prolb.sh` script to adapt the memory per core to be used.

## Prerequisites

Cluster is built with the desired configuration for networking, storage, compute etc. You can see the tutorial or examples folder in this repo for how to set this up.

Dependencies for binary version:

* HPCX with C++ bindings
* OpenMPI shared libraries symbolic links (see `runtime_prolb.sh`)

## Installation

First upload the install packages and cases in your favourite blob storage account.

> NOTE: Provide the `INSTALL_TAR`, `TAR_SAS_URL`, `LICENSE_PORT_IP` and `APP_VERSION` as parameters to the **$azhpc_dir/apps/prolb/install_prolb.sh**

Then copy the apps directory to the cluster.  The `azhpc-scp` can be used to do this:

```
azhpc-scp -r $azhpc_dir/apps hpcuser@headnode:.
```

> Alternatively you can checkout the **azurehpc** repository but you will need to update the paths according to where you put it.

Then run the installer

```
azhpc-run -u hpcuser  apps/prolb/install_prolb.sh 
```

> Note: This will install into `/apps`.

Finally, if the `runtime_prolb.sh` is not part of your compute node installation, run that script on all compute nodes as follows

```
azhpc-run -n compute -u hpcuser apps/prolb/runtime_prolb.sh 
```


## Connect to the headnode

```
azhpc-connect -u hpcuser headnode
```

## Running

Copy the case file to **/data/prolb**

Now, for example on 8 HC44 nodes, you can run as follows:

```
CASE=mycasename
case_dir=/data/prolb/working
mkdir -p $case_dir

qsub -f -k oe -j oe -l select=8:ncpus=44:mpiprocs=44,place=scatter:excl -N prolb $azhpc_dir/apps/prolb/prolb $CASE $case_dir [version] 
```
