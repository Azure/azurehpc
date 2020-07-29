## Install and run LS-DYNA Benchmarks

## Prerequisites

Cluster is built with the desired configuration for networking, storage, compute etc. It is recommended that you start with the example simple_hpc_pbs and use HBv2 VMs. You can find this in the examples folder in this repo.

Dependencies for binary version:

* None

## Installation

First copy the apps directory to the cluster.  The `azhpc-scp` can be used to do this:

```
azhpc-scp -- -r $azhpc_dir/apps hpcuser@headnode:.
```

> Alternatively you can checkout the azurehpc repository but you will need to update the paths according to where you put it.

Next copy the ls-dyna tar.gz file to /mnt/resource on the headnode. Note: You will first need to obtain ls-dyna tar.gz file from Ansys and copy it to the the machine that you will run azhpc-scp from.
```
azhpc-scp <ls-dyna_mpp_install_file.tar.gz> hpcuser@headnode:/mnt/resource/.
azhpc-scp <ls-dyna_hyb_install_file.tar.gz> hpcuser@headnode:/mnt/resource/.
```

The following environment variables can be used to install LS-DYNA:

| Environment Variable   | Default Value | Description                                                                       |
|------------------------|---------------|-----------------------------------------------------------------------------------|
| APP_INSTALL_DIR        | /apps      | The place to install (a LS-DYNA directory will be created here )                   |
| LSDYNA_MPP_INSTALLER_FILE  | /mnt/resource/ls-dyna_mpp_s_R9_3_1_x64_centos65_ifort131_avx2_intelmpi-2018.tar.gz | The full path to the LS-DYNA MPI installer |
| LSDYNA_HYB_INSTALLER_FILE  | /mnt/resource/ls-dyna_hyb_s_R9_3_1_x64_centos65_ifort131_avx2_intelmpi-2018.tar.gz | The full path to the LS-DYNA hybrid installer |


```
azhpc-run -u hpcuser  apps/ls-dyna/install_lsdyna.sh 
```

> Note: This will install into `/apps`.

## Connect to the headnode

```
azhpc-connect -u hpcuser headnode
```

## Setting up the benchmark
```
mkdir -p /data/LS-DYNA/topcrunch/
cd /data/LS-DYNA/topcrunch/
wget https://ftp.lstc.com/anonymous/outgoing/topcrunch/3cars/3cars_rev02.tar.gz .
tar xzvf 3cars_rev02.tar.gz
cd 3cars_rev02
cp pfile_32+ 3cars.pfile
```

### Modify the file 3cars.pfile
remove the directory line so that the file looks like this.
```
gen { nodump nobeamout dboutonly }
decomp { silist 6 sy 48 }
```
Note: If you want to run on the local disks instead of the shared file system, then set the LS_DYNA_RUN_LOCAL variable to yes (i.e. LS_DYNA_RUN_LOCAL=yes) in the -v section of the pbs submission line then add/replace the directory line with this line in the pfile. The run script will modify this value to the correct value for the job.
directory { local /mnt/scratch_shared}


Note: You can download other topcrunch benchmarks from https://ftp.lstc.com/anonymous/outgoing/topcrunch/


## Running
mkdir -p ~/ls-dyna
cd ~/ls-dyna

The `run_lsdyna_impi.pbs` script is ready to use.  Below are all the parameters although the only one that is required if you have followed the previous steps is the LICENSE_INFO for LS-DYNA licensing:

| Environment Variable | Default Value | Description                                                                             |
|----------------------|---------------|-----------------------------------------------------------------------------------------|
| APP_INSTALL_DIR      | /apps         | The place to install (a LS-DYNA directory will be created here )                        |
| LS_DYNA_CASE         | 3cars_rev02   | The benchmark case to run                                    |
| LS_DYNA_INPUT        | 3cars_shell2_150ms.k_rev02 | The input file for the 3cars example            |
| LS_DYNA_PROFILE      | none          | The input file for the 3cars example. If your case does not need a pfile then set this to none            |
| LS_DYNA_EXE_PATH     | /apps/LS-DYNA | Required if using non default LS-DYNA installation path                                 |
| LS_DYNA_DATA_PATH    | /data/LS-DYNA/topcrunch | Required if using non default LS-DYNA topcrunch benchmark path                |
| LICENSE_INFO         | 10.1.0.5      | This must be correct for your environment in order for the code to work                 |
| MPI                  | intelmpi      | Options: intelmpi (only supported option at this time)                                  |

Now, you can run as follows for LS-DYNA:

```
for ppn in 120; do
    for nodes in 1 2 4; do
        LS_DYNA_CASE=3cars_rev02
        LS_DYNA_INPUT=3cars_shell2_150ms.k_rev02
        LS_DYNA_PROFILE=3cars.pfile
        LICENSE_INFO=<network license ip_addr>
        name=LSDYNA_${nodes}n_${ppn}cpn
        LS_DYNA_MPP_EXE=ls-dyna_mpp_s_R9_3_1_x64_centos65_ifort131_avx2_intelmpi-2018
        qsub -l select=${nodes}:ncpus=${ppn}:mpiprocs=${ppn}:ompthreads=1,place=scatter:excl \
            -N $name \
            -v LS_DYNA_INPUT=$LS_DYNA_INPUT,LS_DYNA_PROFILE=$LS_DYNA_PROFILE,LS_DYNA_CASE=$LS_DYNA_CASE,LICENSE_INFO=$LICENSE_INFO,LS_DYNA_MPP_EXE=$LS_DYNA_MPP_EXE \
            ~/apps/ls-dyna/run_lsdyna_impi.pbs
    done
done
```

## Install and run LS-DYNA Benchmarks using [Azure CycleCloud](https://docs.microsoft.com/en-us/azure/cyclecloud/) Cluster

## Prerequisites

These steps require a Azure CycleCloud cluster with PBS.  The `cyclecloud_simple_pbs` template in the examples directory a suitable choice.

It is recommended that you use HBv2 or HB VM instances for the best Performance/cost. Follow the steps in the examples/cyclecloud_simple_pbs/readme.md to setup cycle, import the template and start cluster.

Log in to the headnode of the cluster:

```
    $ cyclecloud connect master -c ls-dyna
```

## Installing LS-DYNA

You will need to copy the /apps/ls-dyna folder to the headnode. Now obtain the ls-dyna installer and copy it to the cluster to /mnt/resource.

The following environment variables can be used:

| Environment Variable   | Default Value | Description                                                                       |
|------------------------|---------------|-----------------------------------------------------------------------------------|
| APP_INSTALL_DIR        | /scratch      | The place to install (a LS-DYNA directory will be created here )                   |
| LSDYNA_INSTALLER_FILE  | /scratch/ls-dyna_mpp_s_R9_3_1_x64_centos65_ifort131_avx2_intelmpi-2018.tar.gz  | The full path to the LS-DYNA  installer |

This will run with the default values:

Run the following to install LS-DYNA on the cluster:

```
export APP_INSTALL_DIR=/scratch
~/apps/ls-dyna/install_ls-dyna.sh
```
## Installing the benchmarks
mkdir -p /data/LS-DYNA/topcrunch/
cd /data/LS-DYNA/topcrunch/
wget https://ftp.lstc.com/anonymous/outgoing/topcrunch/3cars/3cars_rev02.tar.gz .
tar xzvf 3cars_rev02.tar.gz
Note: You can download other topcrunch benchmarks from https://ftp.lstc.com/anonymous/outgoing/topcrunch/

## Running LS-DYNA

The `run_lsdyna_impi.pbs` script is ready to use.  Below are all the parameters although the only one that is required if you have followed the previous steps is the LICENSE_INFO for LS-DYNA licensing:

| Environment Variable | Default Value | Description                                                                             |
|----------------------|---------------|-----------------------------------------------------------------------------------------|
| APP_INSTALL_DIR      | /scratch      | The place to install (a LS-DYNA directory will be created here )                         |
| CASE                 | 3cars_rev02   | The benchmark case to run                                    |
| EX_PATH              | ${DATA_DIR}/LS-DYNA/topcrunch         | Required if using non default LS-DYNA examples                                    |
| LICENSE_INFO         | 10.1.0.5 | This must be correct for your environment in order for the code to work                 |
| MPI                  | intelmpi      | Options: intelmpi (only supported option at this time)                                  |
| LSDYNA_EXE           | ls-dyna_mpp_s_R9_3_1_x64_centos65_ifort131_avx2_intelmpi-2018   | Required if not using the default version   |

Environment variables can be passed to the PBS job with the `-v` flag.

Submit a job as follows on HBv2 instances (remember to substitute the LICENSE_INFO value):

    qsub -l select=2:ncpus=120:mpiprocs=120,place=scatter:excl \
         -v LICENSE_INFO=#INSERT_LICENSE_INFO#,APP_INSTALL_DIR=/scratch,DATA_DIR=/scratch \
         ~/apps/ls-dyna/run_lsdyna_impi.pbs

> Note: multiple environment variables can be set if they are separated by commas, e.g. `-v VAR1=x,VAR2=y`.

The output will be in the working directory for where it was submitted.
