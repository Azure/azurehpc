# AzureHPC ANF and CycleCloud Integration

Outlines the procedure to access a Azure NetApp Files deployed by AzureHPC in CycleCloud (PBS or SLURM).

## Pre-requisites:

* An installed and setup Azure CycleCloud Application Server (instructions [here](https://docs.microsoft.com/en-us/azure/cyclecloud/quickstart-install-cyclecloud) or using the [azurehpc script](https://github.com/Azure/azurehpc/tree/master/examples/cycleserver))
* The Azure CycleCloud CLI (instructions [here](https://docs.microsoft.com/en-us/azure/cyclecloud/install-cyclecloud-cli))
* Azure NetApp Files (ANF) deployed with AzureHPC ([examples/anf_full](https://github.com/Azure/azurehpc/tree/hackathon_june_2020/examples/anf_full)).

## Overview of procedure

The "azhpc ccbuild" command will use a config file to generate AzureHPC projects/Specs and upload them to your default CycleCloud locker. A CycleCloud template parameter file will also be generated based on the parameters you specify in the config file. A default CycleCloud template (PBS or SLURM) (i.e no editing the CC template) will be used to start a CycleCloud cluster using the generated template parameter json file.

## Update the `anf_cycle.json` file (pick pbs or slurm as your preferred scheduler)

Azurehpc provides the `azhpc-init` command that can help here by copying the directory and substituting the unset variables. First run with the `-s` parameter to see which variables need to be set:

```
$ azhpc init -c $azhpc_dir/examples/cc_anf/pbs_anf_cycle.json -d cc_anf -s
```

The variables can be set with the `-v` option where variables are comma separated.  The output from the previous command as a starting point.  The `-d` option is required and will create a new directory name for you.  Please update to whatever `resource_group` you would like to deploy to:

```
$ azhpc-init -c $azhpc_dir/examples/cc_anf/pbs_anf_cycle.json -d cc_anf -v resource_group=azurehpc-cc
```
NOTE: To make sure the value of 'template' is correctly set, ex: 
```
"template": "pbspro_template_1.3.5",
```
you can run below to get existing templates in your CycleCloud server:
```
$  cyclecloud show_cluster -t
```


## Create CycleCloud Cluster with AzureHPC ANF

```
$ cd cc_anf
$ azhpc ccbuild -c pbs_anf_cycle.json
```

## Start CycleCloud Cluster
Go to CycleCloud server portal, find your CycleCloud cluster and click on start.

## Connect to the master node of your cluster, and then check that ANF is mounted.

```
[hpcadmin@jumpbox examples]$ cyclecloud connect master -c anfcycle
Connecting to hpcadmin@10.2.4.9 (anfcycle master) using SSH
Last login: Thu Jun 11 09:16:37 2020 from 10.22.1.4

 __        __  |    ___       __  |    __         __|
(___ (__| (___ |_, (__/_     (___ |_, (__) (__(_ (__|
        |

Cluster: anfcycle
Version: 7.9.5
Run List: recipe[cyclecloud], role[pbspro_master_role], recipe[cluster_init]
[hpcadmin@ip-0A020409 ~]$ df -h
Filesystem               Size  Used Avail Use% Mounted on
devtmpfs                  16G     0   16G   0% /dev
tmpfs                     16G     0   16G   0% /dev/shm
tmpfs                     16G  9.1M   16G   1% /run
tmpfs                     16G     0   16G   0% /sys/fs/cgroup
/dev/sda2                 30G  9.8G   20G  34% /
/dev/sda1                494M   65M  430M  13% /boot
/dev/sda15               495M   12M  484M   3% /boot/efi
/dev/sdb1                 63G   53M   60G   1% /mnt/resource
10.2.8.4:/raymondanfvol  100T  448K  100T   1% /netapps
tmpfs                    3.2G     0  3.2G   0% /run/user/20003
```
