## Install and run Ansys Mechanical Benchmarks

## Prerequisites

Cluster is built with the desired configuration for networking, storage, compute etc. You can see the tutorial or examples folder in this repo for how to set this up.

Recommended cluster setup
Start with the simple_hpc_pbs example. Before you do azhpc-build copy the scripts directory from <azurehpc>/apps/ansys_mechanical to your cluster build directory. First, you will need to add the following line above the "tags" section for the headnode.

"data_disks": [2048, 2048],
    
 Second, add the following section in the scripts section above the pbsdownload piece (~line 90 in the config.json file). 

{
    "script": "add_pkg.sh",
     "tag": "add_pkg",
     "sudo": true
},

Finally, add "add_pkg" to the tags section for the compute nodes (~line 50 in the config.json file).Once these changes are made, then when you build the cluster (azhpc-build) it will get the neccessary scripts to install the prerequsites on the compute nodes

Dependencies for binary version:

* v19.*

## Installation

NOTE: Update the path to the fluent installer tar file in $azhpc_dir/apps/fluent/install_fluent.sh

First copy the apps directory to the cluster.  The `azhpc-scp` can be used to do this:

```
azhpc-scp -u hpcuser -r $azhpc_dir/apps hpcuser@headnode:.
```

## Connect to the headnode

```
azhpc-connect -u hpcuser headnode
```

## Install Ansys Mechanical
cd apps/ansys_mechanical
sudo bash install_mechanical.sh <tar file name> <URL to tar file of the installer>

Example:

sudo bash install_mechanical.sh STRUCTURES_192_LINX64.tar "https://<storage_url>/apps/ansys-mech-19-2/STRUCTURES_192_LINX64.tar?{SAS_KEY}"


## Running

NOTE: In the run script you will need to update the license server.  Currently it is set to localhost which would require a tunnel to be created (currently the ssh tunnel command commented out in the script).

# Copy over the benchmarks. You will need to provide the correct path to the benchmarks.
mkdir -p ~/ansys/v19
cd ~/ansys/v19
wget -q "${STORAGE_ENDPOINT}/ansys-mechanical-benchmarks/BENCH_V190_LINUX.tgz?${SAS_KEY}" -O - | tar -xz

Now, you can run as follows:

```
for ppn in 44 36; do
    for nodes in 1 2; do
        case=V19cg-2
        name=${case}_${nodes}x${ppn}
        mkdir $name
        cd $name
        ln -s ../${case}* .
        qsub -l select=${nodes}:ncpus=${ppn}:mpiprocs=${ppn},place=scatter:excl -N $name ~/apps/ansys_mechanical/run_case_impi.pbs
        cd -
    done
done
```
