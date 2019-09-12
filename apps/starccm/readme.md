## Install and run Starccm+ Benchmarks

## Prerequisites

These steps require a cluster with PBS.  The `simple_hpc_pbs` template in the examples directory a suitable choice.

## Installation

First copy the apps directory to the cluster.  The `azhpc-scp` can be used to do this:

```
azhpc-scp -r $azhpc_dir/apps hpcuser@headnode:.
```

### Install Prerequisites

The `libXt` package is required on the compute nodes.  This can be installed with the `add_reqs.sh` script that is provided (alternatively add to the install steps for the cluster you but with azurehpc).

```
azhpc-run -u hpcuser -n compute ~/apps/starccm/scripts/add_reqs.sh 
```

### Install Starccm+

You must first obtain the starccm installer and copy it to the cluster.  If it is available on the local machine you can copy as follows:

```
azhpc-scp STAR-CCM+14.06.004_02_linux-x86_64-2.12_gnu7.1.tar.gz /mnt/resource/.
```

The following environment variables can be used:

| Environment Variable  | Default Value | Description                                                                       |
|-----------------------|---------------|-----------------------------------------------------------------------------------|
| APP_INSTALL_DIR       | /apps         | The place to install (a starccm directory will be created here                    |
| TMP_DIR               | /mnt/resource | A temporary directory for installation files                                      |
| STARCCM_INSTALLER_DIR | /mnt/resource | The path to the `STAR-CCM+14.06.004_02_linux-x86_64-2.12_gnu7.1.tar.gz` installer |

This will run with the default values:

```
azhpc-run -u hpcuser apps/starccm/install_starccm.sh 
```

# Copy over the benchmark files

The benchmark will need to be copied to the cluster.  The default in the run script is `civil`.  You can copy the `sim` file as follows:

```
azhpc-scp civil.sim hpcuser@headnode:.
```

## Connect to the headnode

```
azhpc-connect -u hpcuser headnode
```

## Running Starccm+

The `run_case.pbs` script is ready to use.  Below are all the parameters although the only one that is required if you have followed the previous steps is the PoD key for StarCCM licensing:

| Environment Variable | Default Value | Description                                                                             |
|----------------------|---------------|-----------------------------------------------------------------------------------------|
| APP_INSTALL_DIR      | /apps         | The place to install (a starccm directory will be created here                          |
| DATA_DIR             | .             | The directory where the sim file is located (relative paths are based on PBS_O_WORKDIR) |
| CASE                 | civil         | The case to run (excluding path and `.sim` extension)                                   |
| PODKEY               |               | This is required for the licensing                                                      |

Environment variables can be passed to the PBS job with the `-v` flag.

Submit a job as follows (remembering to substitute your PoD key value):

    qsub -l select=2:ncpus=60:mpiprocs=60:place=scatter:excl \
        -v PODKEY=#INSERT_POD_KEY# \
        $HOME/apps/starccm/run_case.pbs

> Note: multiple environment variables can be set if they are separated by commas, e.g. `-v VAR1=x,VAR2=y`.

The output will be in the working directory for where it was submitted.

