## SPECStorage 2020

The SPECstorage Solution 2020 benchmark is used to measure the maximum sustainable throughput that a storage 
solution can deliver. The benchmark consists of multiple workloads which represent real data processing file system 
environments. 

[SPEC Storage 2020 Home Page](https://www.spec.org/storage2020/)

## Prerequisites

Cluster is built with the desired configuration for networking, storage, compute etc. The [beegfs_pools](https://github.com/Azure/azurehpc/tree/master/examples/beegfs_pools) template in the examples directory is a suitable choice. This will deploy a BeeGFS PFS using ephemeral disks (L8s_v2) and the attached Standard HDD disks 

After cluster is built, first copy the apps directory to the cluster.  The `azhpc-scp` can be used to do this:

```
azhpc-scp -u hpcuser -r $azhpc_dir/apps hpcuser@headnode:.
```

Then connect to the headnode:
```
azhpc-connect -u hpcuser headnode
```
Or simply create a Azure Virtual machine with CentOS and ssh connect to it.

## Install SPECStorage 2020

The 'install_blast.sh' takes 2 variables: username and password, to access SPEC.org site:

Run the 'install_blast.sh' script:
```
source install_blast.sh <USERNAME> <PASSWORD>
```
## Edit the sfs_rc configuration file

Change folder to your SFS Storage 2020 installation directory. Make a copy of the default sfs_rc file as sfs_test. Follow instructions [SPEC Storage 2020 User Guide](https://www.spec.org/storage2020/docs/usersguide.pdf) section 1.5, to Edit the sfs_test file.
```
cd SPECstorage_2020/
cp sfs_rc sfs_test
vi sfs_test
```

Some key values must be specified:
```
CLIENT_MOUNTPOINTS=<mountpoint mountpoint etc>
USER=<user name>
EXEC_PATH=<pathname>
BENCHMARK=<benchmark name>
NETMIST_LICENSE_KEY=<integer value>
```

Below the example when using the beegfs_pools template and to benchmark EDA workloads:
```
CLIENT_MOUNTPOINTS=headnode:/beegfs
USER=hpcuser
EXEC_PATH=/share/home/hpcuser/SPECstorage_2020/binaries/linux/x86_64/netmist
BENCHMARK=EDA_BLENDED
```

## Run SPEC Storage 2020
```
python3 SM2020 -r sfs_test -s output_test_eda
```
Below the sample results
```
  Business    Requested     Achieved     Avg Lat       Total          Read        Write   Run    #    Cl   Avg File      Cl Data   Start Data    Init File     Max File   Workload       Valid
    Metric      Op Rate      Op Rate        (ms)        KBps          KBps         KBps   Sec   Cl  Proc    Size KB      Set MiB      Set MiB      Set MiB    Space MiB       Name         Run
         1       450.00      450.021       2.155     7281.775     3818.915     3462.860   300    1     5       3424        11051        11051        11051        12056 EDA_BLENDED
```

```




