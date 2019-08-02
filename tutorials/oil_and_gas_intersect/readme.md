# Building a simple PBS compute cluster with a Windows visualization node

This example will create an HPC cluster with a CentOS 7.6 headnode running PBS Pro 19.1 exporting a 4TB NFS space and several CentOS 7.6 HC44 compute nodes; and a Windows visualization node. 
This tutorial uses NFS and RGS but you can also easily set it up with an alternate storage or visualization solution using the examples [here](https://github.com/Azure/azurehpc/tree/master/examples). 

>NOTE: 
- MAKE SURE YOU HAVE FOLLOWED THE STEPS IN [prerequisite](https://github.com/Azure/azurehpc/blob/master/tutorials/prerequisites.md) before proceeding here
- Make sure that the licensing is setup if you want to use intersect. This can be achieved through public ip, peering, route tables, etc.

First initialise a new project.  AZHPC provides the `azhpc-init` command that will help here.  Running with the `-s` parameter will show all the variables that need to be set, e.g.

```
azhpc-init -c $azhpc_dir/tutorials/oil_and_gas_intersect -d oil_and_gas_intersect -s
```

The variables can be set with the `-v` option where variables are comma separated.  The `-d` option is required and will create a new directory name for you.

```
azhpc-init -c $azhpc_dir/tutorials/oil_and_gas_intersect -d oil_and_gas_intersect -v resource_group=azhpc-cluster,win_password=[password or secret.azhpc-vault.winadmin-secret],apps_storage_account=appstorageaccount
```

Create the cluster 

```
cd oil_and_gas_intersect
azhpc-build
```

Allow ~10 minutes for deployment.

To check the status of the VMs run
```
azhpc-status
```
Connect to the headnode and check PBS and NFS

```
azhpc-connect -u hpcuser headnode

Fri Jun 28 09:18:04 UTC 2019 : logging in to headnode (via headnode6cfe86.westus2.cloudapp.azure.com)
[hpcuser@headnode ~]$ pbsnodes -avS
vnode           state           OS       hardware host            queue        mem     ncpus   nmics   ngpus  comment
--------------- --------------- -------- -------- --------------- ---------- -------- ------- ------- ------- ---------
compuc407000003 free            --       --       10.2.4.8        --            346gb      44       0       0 --
compuc407000002 free            --       --       10.2.4.7        --            346gb      44       0       0 --
[hpcuser@headnode ~]$ sudo exportfs -v
/share/apps     <world>(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
/share/data     <world>(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
/share/home     <world>(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
/mnt/resource/scratch
                <world>(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
[hpcuser@headnode ~]$

To check the state of the cluster you can run the following commands
qstat -Q
pbsnodes -avS
df -h
```

Return to the deployment node to install applications
```
exit
```

# Update variables 
Edit intersect full_intersect_2018.2.sh to have the license server and port number, sas url for intersect and eclipse iso 
Where PORT and IP are port and IP address of license server (e.g 23456@17.20.20.1)

Edit install_case_intersect_2018.2.sh to update sas url for the dataset tar file 

# Install applications

First copy the apps directory to the cluster.  The `azhpc-scp` can be used to do this:

```
azhpc-scp -u hpcuser -r $azhpc_dir/apps hpcuser@headnode:.
```

> Alternatively you can checkout the azurehpc repository but you will need to update the paths to apps directory according to where you put it.

If you plan on running intersect, you will be required to set-up your own licensing. Intersect will need a valid PORT@IP to your license
server.


# Intersect installation and running instructions

## Install Intersect and eclipse from iso files

```
azhpc-run -u hpcuser apps/intersect/install_full_intersect_2018.2.sh
```

## Install the data sets for intersect

````
azhpc-run -a apps/intersect/install_case_intersect_2018.2.sh
````

# ResInsight Installation

```
azhpc-run -a apps/resinsight/install_resinsight_v2019.04.sh
```

## Run Intersect

Intersect is run from the headnode (as user hpcuser), First log-in to headnode as user hpcuser.
```
azhpc-connect -u hpcuser headnode
```

Next run

```
qsub -v "casename=<case name>" -l select=2:ncpus=15:mpiprocs=15,place=scatter:excl /apps/intersect/run_intersect_2018.2.sh 
```

Where "case name" (e.g BO_192_192_28) is the intersect case you want to run)

To see if the job is running do
````
qstat -aw
````

# Remote Visualization

To verify setup you can connect to the viznode using RDP (get the RDP file for nvnode from the Azure Portal)
- Username: hpcadmin
- Password: <winadmin-secret>

Check that Y: and Z: drives are mapped to the NFS server

> Note : Y: and Z: drives appears as disconnected while they are not.

[Setup RGS receiver](https://techcommunity.microsoft.com/t5/AzureCAT/Remote-Visualization-in-Azure/ba-p/745184) on your local desktop or laptop and from their connect to the remote visualization node using <public ip address for nvnode>:42966. 

Launch ResInsight from the Y: drive and then open the Intersect EGRID result file located on the Z: drive