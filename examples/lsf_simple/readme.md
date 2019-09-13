# Build a LSF compute cluster

Visualisation: [config.json](https://azurehpc.azureedge.net/?o=https://raw.githubusercontent.com/Azure/azurehpc/master/examples/lsf_simple/config.json)

This example will create an HPC cluster with a CentOS 7.6 headnode running LSF 10.1 exporting a 4TB NFS space and multiple CentOS 7.6 HC44rs compute nodes

>NOTE: MAKE SURE you have followed the steps in [prerequisite](../../tutorials/prerequisites.md) before proceeding here

## Binaries
Before starting make sure that you upload these 4 files :
- lsf10.1_linux2.6-glibc2.3-x86_64.tar.Z
- lsf10.1_linux2.6-glibc2.3-x86_64-509238.tar.Z
- lsf10.1_lsfinstall_linux_x86_64.tar.Z
- lsf_std_entitlement.dat

Into a storage account named `[account]` under container named `[container]`, under the path `/LSF-10.7/`


## Initialize your environment
First initialise a new project. AZHPC provides the `azhpc-init` command that will help here.  Running with the `-s` parameter will show all the variables that need to be set, e.g.

```
$ azhpc-init -c $azhpc_dir/examples/lsf_simple -d lsf_simple -s
```

The variables can be set with the `-v` option where variables are comma separated.  The `-d` option is required and will create a new directory name for you.

```
$ azhpc-init -c $azhpc_dir/examples/lsf_simple -d lsf_simple -v resource_group=azhpc-cluster
```

(Optional) If you would like to change the location and the vm_type you can run the following command

```
$ azhpc-init -c $azhpc_dir/examples/lsf_simple -d lsf_simple -v location=southcentralus,resource_group=azhpc-cluster,vm_type=Standard_HB60rs
```

Make sur to update your `config.json` with the right `[account]` and `[container]` values for these variables :

```
      "lsf_product_sas":"sasurl.[account].[container]/LSF-10.7/lsf10.1_linux2.6-glibc2.3-x86_64.tar.Z",
      "lsf_product_sp7_sas":"sasurl.[account].[container]/LSF-10.7/lsf10.1_linux2.6-glibc2.3-x86_64-509238.tar.Z",
      "lsf_install_sas":"sasurl.[account].[container]/LSF-10.7/lsf10.1_lsfinstall_linux_x86_64.tar.Z",
      "lsf_entitlement_sas":"sasurl.[account].[container]/LSF-10.7/lsf_std_entitlement.dat"
```

## Create the cluster 

```
$ cd lsf_simple
$ azhpc-build
```

Allow ~10 minutes for deployment.

To check the status of the VMs run
```
$ azhpc-status
```
Connect to the headnode and check LSF and NFS

```
$ azhpc-connect headnode
$ bhosts
$ lshosts
$ df -h
```

## Run a test job

- Connect on the headnode under the hpcuser account
- git clone the repo to get application scripts
- submit a ping pong job

```
$ azhpc-connect -u hpcuser headnode
$ git clone https://github.com/Azure/azurehpc.git
$ bsub -R "span[ptile=1]" -n 2 -o %J.log -e %J.err < azurehpc/apps/imb-mpi/ringpingpong.lsf
Job <109> is submitted to default queue <normal>.
$ ll
total 20
-rw-rw-r--.  1 hpcuser hpcuser    0 Sep  5 18:09 109.err
-rw-rw-r--.  1 hpcuser hpcuser 4236 Sep  5 18:09 109.log
drwxrwxr-x. 10 hpcuser hpcuser  217 Sep  5 17:59 azurehpc
-rw-rw-r--.  1 hpcuser hpcuser 2301 Sep  5 18:09 compu3981000001_to_compu3981000002_ringpingpong.109.log
-rw-rw-r--.  1 hpcuser hpcuser 2301 Sep  5 18:09 compu3981000002_to_compu3981000001_ringpingpong.109.log
-rw-rw-r--.  1 hpcuser hpcuser   32 Sep  5 18:09 hosts.109
$ cat 109.log
```


# Known issues

If nodes are unreachable when listed by the `bhosts` command, then connect on the headnode and run `badmin mbdrestart`
