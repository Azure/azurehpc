## Install and run Fluent Benchmarks

## Prerequisites

Cluster is built with the desired configuration for networking, storage, compute etc. You can see the tutorial or examples folder in this repo for how to set this up.

Dependencies for binary version:

* None

## Installation

First copy the apps directory to the cluster.  The `azhpc-scp` can be used to do this:

```
azhpc-scp -r $azhpc_dir/apps hpcuser@headnode:.
```

> Alternatively you can checkout the azurehpc repository but you will need to update the paths according to where you put it.

Next copy the convergecfd tar.gz file to /mnt/resource on the headnode
```
azhpc-scp <convergecfd_install_file.tar.gz> hpcuser@headnode:/mnt/resource/.
```

```
azhpc-run -u hpcuser  apps/convergecfd/install_convergecfd.sh 
```

> Note: This will install into `/apps`.

## Connect to the headnode

```
azhpc-connect -u hpcuser headnode
```


## Running
mkdir -p ~/convergecfd
cd ~/convergecfd

Now, you can run as follows:

```
for ppn in 112 116 120; do
    for nodes in 1 2 4 8 16; do
        CCFD_VERSION=3.0.12
        EX_PATH=/apps/Convergent_Science/CONVERGE/$CCFD_VERSION/example_cases/Internal_Combustion_Engines/Gasoline_spark_ignition_PFI
        CASE=SI8_engine_premix_SAGE
        LICENSE_INFO=2765@<ip_addr>
        name=SI8_SAGE_${nodes}n_${ppn}cpn
        cp ~/apps/convergecfd/run_ccfd.sh .
        qsub -l select=${nodes}:ncpus=${ppn}:mpiprocs=${ppn},place=scatter:excl \
            -N $name \
            -v CCFD_VERSION=$CCFD_VERSION,EX_PATH=$EX_PATH,CASE=$CASE,LICENSE_INFO=$LICENSE_INFO \
            ./run_ccfd.sh
    done
done
```
