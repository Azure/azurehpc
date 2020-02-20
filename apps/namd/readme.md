## Install and run NAMD 

## Prerequisites

Cluster is built with the desired configuration for networking, storage, compute etc. You can see the tutorial or examples folder in this repo for how to set this up. Spack is installed (See [here](../spack/readme.md) for details).

Dependencies for binary version:

* None


First copy the apps directory to the cluster in a shared directory.  The `azhpc-scp` can be used to do this:

```
azhpc-scp -r $azhpc_dir/apps/. hpcuser@headnode:.
```

> Alternatively you can checkout the azurehpc repository but you will need to update the paths according to where you put it.


## Connect to the headnode

```
azhpc-connect -u hpcuser headnode
```

## Installation

### Run namd install script
```
apps/namd/install_namd_openmpi.sh 
```
> Note: Set SKU_TYPE environmental to the type of sku you are using (e.h hb, hbv2 or hc). NAMD_SOURE_TAR_GZ_LOC to the location of the namd source code (e.g NAMD_2.13_Source.tar.gz). Set NAMD_SMP to "smp" if you want to build the smp version. Set NAMD_MEMOPT to "--with-memopt" if you want to built the memopt version of namd.

## Running


Now, you can run namd on hbv2 as follows:

```
qsub -l select=2:ncpus=120:mpiprocs=120 -v SKU_TYPE=hbv2,INPUTDIR=/path/to/inputfiles apps/namd/run_namd_openmpi.pbs

```
> Where SKU_TYPE is the sku type you are running on and INPUTDIR contains the location of namd input files.

