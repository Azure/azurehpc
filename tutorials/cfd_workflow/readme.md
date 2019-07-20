# Build a simple PBS compute cluster with a Windows visualization node for OpenFOAM and ParaView

This example will create an HPC cluster with a CentOS 7.6 headnode running PBS Pro 19.1 exporting a 4TB NFS space and several CentOS 7.6 HC44 compute nodes; and a Windows visualization node.

>NOTE: MAKE SURE YOU HAVE FOLLOWED THE STEPS IN [prerequisite](../prerequisites.md) before proceeding here

First initialise a new project.  AZHPC provides the `azhpc-init` command that will help here.  Running with the `-s` parameter will show all the variables that need to be set, e.g.

```
$ azhpc-init -c $azhpc_dir/tutorials/cfd_workflow -d cfd_workflow
```

The variables can be set with the `-v` option where variables are comma separated.  The `-d` option is required and will create a new directory name for you.

```
azhpc-init -c $azhpc_dir/tutorials/cfd_workflow -d cfd_workflow -v location=southcentralus,resource_group=azhpc-cluster,win_password=[password or secret.azhpc-vault.winadmin-secret]
```

Create the cluster 

```
cd cfd_workflow
```

Note: Before running the next command make sure that you are running in a region that has Hc instances and you have quota there. Alternatively, you can change the instance type to Hb an run in a region where you have quota

```
azhpc-build
```

Allow ~10 minutes for deployment.

To check the status of the VMs run
```
azhpc-status
```
Connect to the headnode and check PBS and NFS

```
$ azhpc-connect -u hpcuser headnode
Fri Jun 28 09:18:04 UTC 2019 : logging in to headnode (via headnode6cfe86.westus2.cloudapp.azure.com)
[hpcuser@headnode ~]$ pbsnodes -avS
vnode           state           OS       hardware host            queue        mem     ncpus   nmics   ngpus  comment
--------------- --------------- -------- -------- --------------- ---------- -------- ------- ------- ------- ---------
compuc407000003 free            --       --       10.2.4.8        --            224gb      60       0       0 --
compuc407000002 free            --       --       10.2.4.7        --            224gb      60       0       0 --
[hpcuser@headnode ~]$ sudo exportfs -v
/share/apps     <world>(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
/share/data     <world>(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
/share/home     <world>(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
/mnt/resource/scratch
                <world>(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
[hpcuser@headnode ~]$
```

To check the state of the cluster you can run the following commands
* `qstat -Q`
* `df -h`

Return to the deployment node to install applations
```
exit
```

# Install applications

First copy the apps directory to the cluster.  The `azhpc-scp` can be used to do this:

```
azhpc-scp -u hpcuser -r $azhpc_dir/apps hpcuser@headnode:.
```

> Alternatively you can checkout the azurehpc repository but you will need to update the paths according to where you put it.

## Install OpenFOAM from tarball

This install will download the binaries and install:

```
azhpc-run -u hpcuser apps/openfoam_org/install_openfoam.sh```
```

> Alternatively the `install_openfoam_6_impi2018_gcc82.sh` script will build from source.

## Paraview Installation

This will install the Windows version of ParaView in the shared directory which will be mounted on the Windows VM.

```
azhpc-run -u hpcuser apps/paraview/install_paraview_v5.6.1.sh
```

## Run OpenFOAM 

OpenFOAM is run on the headnode. First, Log-in to headnode as hpcuser
```
azhpc-connect -u hpcuser headnode
```

Run motorbike_2m model
```
qsub -l select=2:ncpus=60:mpiprocs=60 -N OF_motorbike_2m $HOME/openfoam_org/motorbike_2m.sh
```

On 2 Hb nodes (120 cores) it takes ~3-4 min to run
````
qstat -aw
````

# Remote Visualization

Connect to the viznode using RDP (get the RDP file for nvnode from the Azure Portal)
- Username: hpcadmin
- Password: <winadmin-secret>

Check that Y: and Z: drives are mapped to the NFS server

> Note : Y: and Z: drives appears as disconnected while they are not.

Launch Paraview from the Y: drive (Y:\paraview\ParaView-5.6.1-Windows-msvc2015-64bit\bin\paraview) and then, from paraview, open the openfoam result file located on the Z: drive (Z:\motorbike_scaled\motorBike.foam)
