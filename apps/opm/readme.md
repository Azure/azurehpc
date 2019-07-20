#OPM installation and running instructions

##Prerequisites
It is assumed that the OPM binaries are built and tar uploaded at **\$HPC_APPS_STORAGE_ENDPOINT/opm/\$APP_VERSION/opm.tar.gz?\$HPC_APPS_SASKEY**. Script to build OPM 2019.4 can be found in build_opm_2019_04.sh but note that the build and steps to run OPM here are only tested with that version on the CentOS 7.6 HPC image. 

## Setup cluster
Build a simple PBS cluster using config file at https://azurecat.visualstudio.com/hpc-apps/_git/azhpc?path=%2Fexamples%2Fsimple_cluster%2Fconfig.json&version=GBmaster

## Install OPM 
**Update config.json file with sasurl** for where OPM tar mentioned in prereq is uploaded
To build from scratch use full_install_opm.sh in config.json  
Note: OPM requires that lapack be installed on the compute nodes. There is a script to do this (scripts/app_opm_req.sh)
```
azhpc-install -a '../azhpc/apps/opm/config.json'
```

Application log file will be located in a file named **build_opm_2_32_xxxxxxxx-xxxxxx.ox**

## Connect to the headnode

```
azhpc-connect -u hpcuser headnode
```

## Clone the azhpc repo
Before submitting jobs from the **headnode** clone the **hpc-apps** repo
>>> We need to clean up this step so no clone is neccessary
> Note: In its current form you will need to add the ssh key to azure devops since it is a private repo
```
git clone git@github.com:Azure/azurehpc.git
. azurehpc/install.sh
```

## Run the OPM norne scenario
To run on a single node with 30 cores run
```
qsub -l select=1:ncpus=30:mpiprocs=30 $azhpc_dir/apps/opm/flow_norne.sh
```

To run on two node with 30 cores run
```
qsub -l select=2:ncpus=15:mpiprocs=15 $azhpc_dir/apps/opm/flow_norne.sh
```

Notes:
- All job outputs files will be stored in the user home dir with the prefix name OPM_norne.o<job id>.