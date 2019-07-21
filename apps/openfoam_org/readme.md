# OpenFOAM installation and running instructions

First copy the apps directory to the cluster.  The `azhpc-scp` can be used to do this:

    azhpc-scp -u hpcuser -r $azhpc_dir/apps hpcuser@headnode:.


> Alternatively you can checkout the azurehpc repository but you will need to update the paths according to where you put it.

## Install OpenFOAM from source

For this the headnode needs to be a HC node with CentOS-HPC-7.6 upwards

```
azhpc-run -u hpcuser $azhpc_dir/apps/openfoam_org/full_openfoam.sh
```


## Install OpenFOAM from tarball

```
azhpc-run -u hpcuser $azhpc_dir/apps/openfoam_org/tar_openfoam.sh
```

## Run OpenFOAM 

OpenFOAM is run on the headnode. First, Log-in to headnode as hpcuser (using "azhpc-connect -u hpcuser headnode").
Then git clone the azhpc repo

Run motorbike_2m model
```
qsub -l select=1:ncpus=30:mpiprocs=30,place=scatter:excl $azhpc_dir/apps/openfoam_org/motorbike_2m.sh
```
Run OpenFoam tutorial (Not working yet. Does not recognize changing core counts)
```
qsub -l select=1:ncpus=30:mpiprocs=30,place=scatter:excl -- $azhpc_dir/apps/openfoam_org/run_tutorial.sh incompressible simpleFoam rotorDisk
```
You can run a different tutorial by changing the first (Tutorial name e.g incompressible), second (Solver, e.g simpleFoam) and third (case name, e.g SimpleFoam) arguments. 

