## Install and run Ansys Mechanical Benchmarks

## Prerequisites

Cluster is built with the desired configuration for networking, storage, compute etc. You can see the tutorial or examples folder in this repo for how to set this up.

Recommended that you start with the cfd_workflow tutorial for the cluster setup since you need extra disk space for the install and running of the benchmarks.

Dependencies for binary version:

* v19.*

## Installation

NOTE: Update the path to the installer tar file in $azhpc_dir/apps/ansys_mechanical/install_mechanical.sh

First copy the apps directory to the cluster.  The `azhpc-scp` can be used to do this:

```
azhpc-scp -u hpcuser -r $azhpc_dir/apps hpcuser@headnode:.
```

### Install Prerequisite Software
```
azhpc-run -u hpcuser -n "headnode compute" ~/apps/ansys_mechanical/scripts/add_pkgs.sh
```

### Install Ansys Mechanical
```
azhpc-run -u hpcuser -n headnode ~/apps/ansys_mechanical/install_mechanical.sh \<tar file name\> \<URL to tar file of the installer\>
```

Example:
```
azhpc-run -u hpcuser -n headnode ~/apps/ansys_mechanical/install_mechanical.sh STRUCTURES_192_LINX64.tar "https://<storage_url>/apps/ansys-mech-19-2/STRUCTURES_192_LINX64.tar?{SAS_KEY}"
```

## Connect To Headnode

```
azhpc-connect -u hpcuser headnode
```

## Run Benchmark

### Copy over the benchmarks. You will need to provide the correct path to the benchmarks.
```
mkdir -p ~/ansys/v19
cd ~/ansys/v19
wget -q "${STORAGE_ENDPOINT}/ansys-mechanical-benchmarks/BENCH_V190_LINUX.tgz?${SAS_KEY}" -O - | tar -xz
```

### Update License Server
NOTE: In the run script you will need to __update the license server__.  Currently it is set to localhost which would require a tunnel to be created (currently the ssh tunnel command commented out in the script).

### Submitting Jobs
Now, you can now run a set of runs as follows from the ~/ansys/v19 directory

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
