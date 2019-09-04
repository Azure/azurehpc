## Install and run Starccm+ Benchmarks

## Prerequisites

Cluster is built with the desired configuration for networking, storage, compute etc. 


## Installation

NOTE: Update the path to the starccm installer tar file in $azhpc_dir/apps/starccm/install_starccm.sh

First copy the apps directory to the cluster.  The `azhpc-scp` can be used to do this:

```
azhpc-scp -u hpcuser -r $azhpc_dir/apps hpcuser@headnode:.
```

### Install Prerequisites
```
azhpc-run -u hpcuser -n compute ~/apps/starccm/scripts/add_reqs.sh 
```

### Install Starccm+
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

