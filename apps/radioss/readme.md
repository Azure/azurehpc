## Install and run Radioss Benchmarks using azurehpc cluster

## Prerequisites

These steps require a cluster with PBS.  The `simple_hpc_pbs` template in the examples directory a suitable choice.

## Installation

First copy the apps directory to the cluster.  The `azhpc-scp` can be used to do this:

```
azhpc-scp -r $azhpc_dir/apps hpcuser@headnode:.
```

### Install Prerequisites

```
azhpc-run -u hpcuser sudo yum install -y p7zip
```

### Install Radioss

You must first obtain the radioss installer and copy it to the cluster.  If it is available on the local machine you can copy as follows:

```
azhpc-scp hwSolvers2018_linux64.bin hpcuser@headnode:/mnt/resource/.
azhpc-scp hwSolvers2018.0.1_hotfix_linux64.bin hpcuser@headnode:/mnt/resource/.
```

The following environment variables can be used:

| Environment Variable  | Default Value | Description                                                                       |
|------------------------|--------------------------------------------------------------------|-----------------------------------------------------------------------------------------|
| APP_INSTALL_DIR        | /apps                                                              | The place to install (a radioss directory will be created here                      |
| TMP_DIR                | /mnt/resource | A temporary directory for installation files                                                                                                 |
| RADIOSS_INSTALLER_FILE | /mnt/resource/hwSolvers2018_linux64.bin| The full path to the `hwSolvers2018_linux64.bin` installer |
| RADIOSS_HOTFIX_FILE | /mnt/resource/hwSolvers2018.0.1_hotfix_linux64.bin| The full path to the `hwSolvers2018.0.1_hotfix_linux64.bin` installer |

This will run with the default values:

```
apps/radioss/install_radioss.sh

```

> Note: This will install into `/apps/altair/2018`.


# Copy over the benchmark files

The benchmark will need to be copied to the cluster.  The default in the run script is `T10M`.  You can setup it as follows:

```

azhpc-run -u hpcuser mkdir -p /data/radioss/T10M
azhpc-scp T10M.7z  hpcuser@headnode:/data/radioss/T10M/T10M.7z
azhpc-run -u hpcuser "cd /data/radioss/T10M; 7za e T10M.7z"
azhpc-run -u hpcuser "cd /data/radioss/T10M;  mv *.inc includes/"
azhpc-run -u hpcuser "cd /data/radioss/T10M;  mv *.xref includes/"
```

## Connect to the headnode

```
azhpc-connect -u hpcuser headnode
```

## Running Radioss

The `run_T10M.pbs` script is ready to use.  Below are all the parameters although the only one that is required if you have followed the previous steps for Radioss licensing:

| Environment Variable | Default Value | Description                                                                             |
|----------------------|---------------|-----------------------------------------------------------------------------------------|
| APP_INSTALL_DIR      | /apps         | The place where radioss is installed                                                    |
| DATA_DIR             | /data         | The directory where the sim file is located (relative paths are based on PBS_O_WORKDIR) |
| CASE                 | T10M          | The model to run (excluding path)                                   |
| LIC_SRV              |               | This is required for the licensing                                                      |

Environment variables can be passed to the PBS job with the `-v` flag.

Submit a job as follows (remembering to insert the right LIC_SRV value):

    qsub -l select=2:ncpus=44:mpiprocs=44:ompthreads=1,place=scatter:excl \
        -v LIC_SRV=#INSERT_LIC_SRV_IP_ADDR# \
        apps/radioss/run_T10M.pbs

> Note: multiple environment variables can be set if they are separated by commas, e.g. `-v VAR1=x,VAR2=y`.

The output will be in the working directory for where it was submitted.

## Install and run Radioss Benchmarks using [Azure CycleCloud](https://docs.microsoft.com/en-us/azure/cyclecloud/) Cluster

## Prerequisites

These steps require a Azure CycleCloud cluster with PBS.  The `cyclecloud_simple_pbs` template in the examples directory a suitable choice. 
Note: Before creating the cluster with above template we need to update the default project spec to install the Radioss dependency. Add the following in specs/default/cluster-init/scripts/01_install_packages.sh to have the following:

```
#!/bin/bash

yum -y install p7zip
```
Follow the steps in the examples/cyclecloud_simple_pbs/readme.md to setup cycle, import the template and start cluster.

Log in to the headnode of the cluster:

```
    $ cyclecloud connect master -c radioss
```

## Installing Radiosss

You will need to copy the /apps/radioss folder to the headnode. Now obtain the Radioss installer and copy it to the cluster to /mnt/resource. 

The following environment variables can be used:
| Environment Variable  | Default Value | Description                                                                       |
|------------------------|--------------------------------------------------------------------|-----------------------------------------------------------------------------------------|
| APP_INSTALL_DIR        | /scratch                                                              | The place to install (a radioss directory will be created here                      |
| TMP_DIR                | /mnt/resource | A temporary directory for installation files                                                                                                 |
| RADIOSS_INSTALLER_FILE | /mnt/resource/hwSolvers2018_linux64.bin| The full path to the `hwSolvers2018_linux64.bin` installer |
| RADIOSS_HOTFIX_FILE | /mnt/resource/hwSolvers2018.0.1_hotfix_linux64.bin| The full path to the `hwSolvers2018.0.1_hotfix_linux64.bin` installer |

This will run with the default values:

Run the following to install Radioss on the cluster:

```
export APP_INSTALL_DIR=/scratch
apps/radioss/install_radioss.sh
```

## Running Radioss

The benchmark will need to be copied to the cluster.  The default in the run script is `T10M`.  You can copy over the files to the headnode under /scratch.

The `run_T10M.pbs` script is ready to use.  Below are all the parameters although the only one that is required if you have followed the previous steps is the LIC_SRV for the Altair licensing:

| Environment Variable | Default Value | Description                                                                             |
|----------------------|---------------|-----------------------------------------------------------------------------------------|
| APP_INSTALL_DIR      | /scratch      | The place to install (a radioss directory will be created here                          |
| DATA_DIR             | /scratch      | The directory where the sim file is located (relative paths are based on PBS_O_WORKDIR) |
| CASE                 | T10M          | The case to run (excluding path)                                   |
| LIC_SRV              |               | This is required for the licensing                                                      |

Environment variables can be passed to the PBS job with the `-v` flag.

Submit a job as follows (remembering to insert the right LIC_SRV value):

    qsub -l select=2:ncpus=44:mpiprocs=44:ompthreads=1,place=scatter:excl \
         -v LIC_SRV=#INSERT_LIC_SRV#,APP_INSTALL_DIR=/scratch,DATA_DIR=/scratch \
         apps/radios/run_T10M.pbs

> Note: multiple environment variables can be set if they are separated by commas, e.g. `-v VAR1=x,VAR2=y`.

The output will be in the working directory for where it was submitted.
