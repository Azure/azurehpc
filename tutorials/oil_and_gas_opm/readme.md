# Build a PBS compute cluster with a Windows visualization node to run OPM and ResInsight

This example will create an HPC cluster with a CentOS 7.6 headnode running PBS Pro 19.1 exporting a 4TB NFS space and multiple CentOS 7.6 HB60rs compute nodes; and a Windows visualization node. 
This tutorial uses NFS and RDP for simplicity but you can also easily set it up with an alternate storage or visualization solution using the examples [here](https://github.com/Azure/azurehpc/tree/master/examples). 

>NOTE: 
- MAKE SURE you have followed the steps in [prerequisite](../prerequisites.md) before proceeding here

First initialise a new project.  AZHPC provides the `azhpc-init` command that will help here.  Running with the `-s` parameter will show all the variables that need to be set, e.g.

```
azhpc-init -c $azhpc_dir/tutorials/oil_and_gas_opm -d oil_and_gas_opm -s
```

The variables can be set with the `-v` option where variables are comma separated.  The `-d` option is required and will create a new directory name for you.

```
azhpc-init -c $azhpc_dir/tutorials/oil_and_gas_opm -d oil_and_gas_opm -v location=southcentralus,resource_group=azhpc-cluster,win_password=[password or secret.azhpc-vault.winadmin-secret]
```

Create the cluster 

```
cd oil_and_gas_opm
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

To check the state of the cluster you can run the following commands
azhpc-connect -u hpcuser headnode
qstat -Q
pbsnodes -avS
df -h
```


Return to the deployment node to install applications
```
exit
```

# Install applications

First copy the apps directory to the cluster.  The `azhpc-scp` can be used to do this:

```
azhpc-scp -r $azhpc_dir/apps hpcuser@headnode:.
```

> Alternatively you can checkout the azurehpc repository but you will need to update the paths to apps directory according to where you put it.

## Install OPM

Run the install script:

```
azhpc-run -u hpcuser apps/opm/install_opm.sh
```

> Note: this can be run when on the cluster

OPM requires that lapack be installed on all of the compute nodes. The `scripts/app_opm_req.sh` script was created and has been added as an install step in the `config.json`.  

> The `full_install_opm.sh` can be used to build everything from source.

# ResInsight Installation

Run the install script:

```
azhpc-run -u hpcuser apps/resinsight/install_resinsight_v2019.04.sh
```


## Connect to the headnode

```
azhpc-connect -u hpcuser headnode
```

## Run the OPM norne scenario
To run on a single node with 30 cores run
```
qsub -l select=1:ncpus=30:mpiprocs=30,place=scatter:excl $HOME/apps/opm/flow_norne.sh
```

To run on two node with 30 cores run
```
qsub -l select=2:ncpus=15:mpiprocs=15,place=scatter:excl $HOME/apps/opm/flow_norne.sh
```

Notes:
- The job outputs files will be stored in \data\opm-data\norne\out_parallel.


# Remote Visualization

Connect to the viznode using RDB (get the RDP file for nvnode from the Azure Portal)
- Username: hpcadmin
- Password: <winadmin-secret>

Check that Y: and Z: drives are mapped to the NFS server

> Note : Y: and Z: drives appears as disconnected while they are not.

Launch ResInsight from the Y: drive (Y:\resinsight\ResInsight-2019.04.0_oct-4.0.0_souring_win64\ResInsight) and then, from ResInsight, click import eclipse file. The result file is located on the Z: drive (Z:\opm-data\norne\out_parallel\NORNE_ATW2013.EGRID)
