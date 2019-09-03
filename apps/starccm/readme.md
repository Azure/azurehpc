## Install and run Fluent Benchmarks

## Prerequisites

Cluster is built with the desired configuration for networking, storage, compute etc. 

Recommended cluster setup
Start with the simple_hpc_pbs example. Before you do azhpc-build copy the scripts directory from <azurehpc>/apps/starccm to your cluster build directory. First, you will need to add the following line above the "tags" section for the headnode.

"data_disks": [2048, 2048],
    
 Second, add the following section in the scripts section above the pbsdownload piece (~line 90 in the config.json file). 

{
    "script": "add_reqs.sh",
    "tag": "add_reqs",
    "sudo": true
},

Finally, add "add_reqs" to the tags section for the compute nodes (~line 50 in the config.json file).Once these changes are made, then when you build the cluster (azhpc-build) it will get the neccessary scripts to install the prerequsites on the compute nodes

Dependencies for binary version:

* v19.*

## Installation

NOTE: Update the path to the starccm installer tar file in $azhpc_dir/apps/starccm/install_starccm.sh

First copy the apps directory to the cluster.  The `azhpc-scp` can be used to do this:

```
azhpc-scp -u hpcuser -r $azhpc_dir/apps hpcuser@headnode:.
```

> Alternatively you can checkout the azurehpc repository but you will need to update the paths according to where you put it.

```
azhpc-run -u hpcuser  apps/starccm/install_starccm.sh 
```

> Note: This will install into `/apps`.

## Connect to the headnode

```
azhpc-connect -u hpcuser headnode
```

# Copy over the benchmark files
In this case, copy the civil.sim.tgz benchmark to the /data/starccm/ location and untar it.

## Preparing to Run Starccm+
```
mkdir starccm
cd starccm
cp ~/apps/starccm/run_civil_ompi4.pbs .
```
## Update License Information
You will need to update the license information in the run_civil.pbs script. This will either be a podkey (line 16) or the CMLMD_LICENSE_FILE variable (line 22). 

## Run Starccm+

qsub -l select=2:ncpus=60:mpiprocs=60:mem=220gb run_civil_ompi4.pbs

