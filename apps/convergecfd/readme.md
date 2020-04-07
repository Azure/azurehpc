## Install and run ConvergeCFD Benchmarks

## Prerequisites

Cluster is built with the desired configuration for networking, storage, compute etc. It is recommended that you start with the example simple_hpc_pbs and use HBv2 VMs. You can find this in the examples folder in this repo.

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

The following environment variables can be used to install ConvergeCFD:

| Environment Variable   | Default Value | Description                                                                       |
|------------------------|---------------|-----------------------------------------------------------------------------------|
| APP_INSTALL_DIR        | /scratch      | The place to install (a Convergent_Science directory will be created here )                   |
| CONVERGECFD_INSTALLER_FILE | /mnt/resource/Convergent_Science_Full_Package-3.0.12.tar.gz | The full path to the ConvergeCFD  installer |


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

The `run_ccfd_3.0_impi.pbs` script is ready to use.  Below are all the parameters although the only one that is required if you have followed the previous steps is the LICENSE_INFO for ConvergeCFD licensing:

| Environment Variable | Default Value | Description                                                                             |
|----------------------|---------------|-----------------------------------------------------------------------------------------|
| APP_INSTALL_DIR      | /scratch      | The place to install (a Convergent_Science directory will be created here )                         |
| CASE                 | SI8_engine_PFI_SAGE         | The benchmark case to run                                    |
| EX_PATH              | ${APP_INSTALL_DIR}/Convergent_Science/Example_Cases/$CCFD_VERSION/Internal_Combustion_Engines/Gasoline_spark_ignition_PFI         | Required if using non default ConvergeCFD examples                                    |
| LICENSE_INFO         | 2765@10.1.0.5 | This must be correct for your environment in order for the code to work                 |
| MPI                  | intelmpi      | Options: intelmpi (only supported option at this time)                                  |
| CONVERGECFD_VERSION  | 3.0.12        | Required if not using the default version                                               |

Now, you can run as follows for ConvergeCFD 3.0+ runs:

```
for ppn in 116 120; do
    for nodes in 1 2 4 8 16; do
        CCFD_VERSION=3.0.12
        EX_PATH=/apps/Convergent_Science/Example_Cases/$CCFD_VERSION/Internal_Combustion_Engines/Gasoline_spark_ignition_PFI
        CASE=SI8_engine_PFI_SAGE
        LICENSE_INFO=2765@<ip_addr>
        name=SI8_SAGE_${nodes}n_${ppn}cpn
        qsub -l select=${nodes}:ncpus=${ppn}:mpiprocs=${ppn},place=scatter:excl \
            -N $name \
            -v CCFD_VERSION=$CCFD_VERSION,EX_PATH=$EX_PATH,CASE=$CASE,LICENSE_INFO=$LICENSE_INFO \
            ~/apps/convergecfd/run_ccfd_3.0_impi.pbs
    done
done
```

## Install and run ConvergeCFD Benchmarks using [Azure CycleCloud](https://docs.microsoft.com/en-us/azure/cyclecloud/) Cluster

## Prerequisites

These steps require a Azure CycleCloud cluster with PBS.  The `cyclecloud_simple_pbs` template in the examples directory a suitable choice.

It is recommended that you use HBv2 or HB VM instances for the best Performance/cost. Follow the steps in the examples/cyclecloud_simple_pbs/readme.md to setup cycle, import the template and start cluster.

Log in to the headnode of the cluster:

```
    $ cyclecloud connect master -c convergecfd
```

## Installing ConvergeCFD

You will need to copy the /apps/convergecfd folder to the headnode. Now obtain the convergecfd installer and copy it to the cluster to /mnt/resource.

The following environment variables can be used:

| Environment Variable   | Default Value | Description                                                                       |
|------------------------|---------------|-----------------------------------------------------------------------------------|
| APP_INSTALL_DIR        | /scratch      | The place to install (a Convergent_Science directory will be created here )                   |
| CONVERGECFD_INSTALLER_FILE | /mnt/resource/Convergent_Science_Full_Package-3.0.12.tar.gz | The full path to the ConvergeCFD  installer |

This will run with the default values:

Run the following to install ConvergeCFD on the cluster:

```
export APP_INSTALL_DIR=/scratch
apps/convergecfd/install_convergecfd.sh
```

## Running ConvergeCFD

The benchmarks files are in $APP_INSTALL_DIR/Convergent_Science/CONVERGE/$CCFD_VERSION/example_cases.  The default in the run script is SI8_engine_PFI_SAGE.  

The `run_ccfd_3.0_impi.pbs` script is ready to use.  Below are all the parameters although the only one that is required if you have followed the previous steps is the LICENSE_INFO for ConvergeCFD licensing:

| Environment Variable | Default Value | Description                                                                             |
|----------------------|---------------|-----------------------------------------------------------------------------------------|
| APP_INSTALL_DIR      | /scratch      | The place to install (a Convergent_Science directory will be created here )                         |
| CASE                 | SI8_engine_PFI_SAGE         | The benchmark case to run                                    |
| EX_PATH              | ${APP_INSTALL_DIR}/Convergent_Science/Example_Cases/$CCFD_VERSION/Internal_Combustion_Engines/Gasoline_spark_ignition_PFI         | Required if using non default ConvergeCFD examples                                    |
| LICENSE_INFO         | 2765@10.1.0.5 | This must be correct for your environment in order for the code to work                 |
| MPI                  | intelmpi      | Options: intelmpi (only supported option at this time)                                  |
| CONVERGECFD_VERSION  | 3.0.12        | Required if not using the default version                                               |

Environment variables can be passed to the PBS job with the `-v` flag.

Submit a job as follows on HBv2 instances (remember to substitute the LICENSE_INFO value):

    qsub -l select=2:ncpus=120:mpiprocs=120,place=scatter:excl \
         -v LICENSE_INFO=#INSERT_LICENSE_INFO#,APP_INSTALL_DIR=/scratch,DATA_DIR=/scratch \
         apps/convergecfd/run_ccfd_3.0_impi.pbs

> Note: multiple environment variables can be set if they are separated by commas, e.g. `-v VAR1=x,VAR2=y`.

The output will be in the working directory for where it was submitted.
