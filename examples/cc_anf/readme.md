# Building the infrastructure

Here we will explain how to deploy a full system with a VNET, JUMPBOX, CYCLESERVER and ANF by using building blocks.

## Step 1 - install azhpc
after cloning azhpc, source the install.sh script

```
$ git clone https://github.com/Azure/azurehpc.git
$ cd azurehpc
$ . install.sh
$ cd ..
```

## Step 2 - Initialize the configuration files
Create a working directory from where you will do the deployment and configuration update. Don't work directly from the cloned repo.

```
$ mkdir cc_anf
$ cd cc_anf
```

Then copy the init.sh and variables.json from examples/cc_anf to your working directory.

```
$ cp $azhpc_dir/examples/cc_anf/init.sh .
$ cp $azhpc_dir/examples/cc_anf/variables.json .
```

Edit the variables.json to match your environment. Give a unique value to `uuid`. An existing keyvault can be referenced if needed.

```json
{
  "variables": {
    "resource_group": "my resource group",
    "location": "my location",
    "key_vault": "kv{{variables.uuid}}",
    "uuid": "unique value",
    "projectstore": "locker{{variables.uuid}}"
  }
}
```

Run the init.sh script which will copy all the config files of the building blocks and initialize the variables by using the variables.json updated above.

```
$ ./init.sh
```

## Step 2 - Build the system

The first command will create the required pre-requisites for CycleCloud like a Key Vault, generate a password and store it in the Vault.
The second command will buil all the resources and create a SLURM cluster.

```
$ azhpc-build --no-vnet -c prereqs.json
$ azhpc-build 
```
The build process should take about 13 minutes.

## Step 3 - Upload application scripts

Upload the AzureHPC application scripts onto the /apps share created on the Jumpbox. These scripts will be used from the master and compute nodes provisioned by CycleCloud.

```
$ azhpc-scp -- -r $azhpc_dir/apps/. hpcadmin@jumpbox:/apps
```

## Step 4 - Start the PBS cluster in CycleCloud

To Start the SLURM cluster attached to ANF:

```
$ cyclecloud start_cluster slurmcycle
```

Retrieve the cluster status by running this
```
$ cyclecloud show_cluster slurmcycle | grep master | xargs | cut -d ' ' -f 2
$ cyclecloud show_nodes -c slurmcycle --format=json | jq -r '.[0].State'
```

## Step 5 - Connect to CycleServer UI

Retrieve the CycleServer DNS name from the azure portal

Retrieve the CycleCloud admin password from the logs 

```
$ grep password azhpc_install_config/install/*.log
```

Connect to the CycleCloud Web Portal `https://fqdn-of-cycleserver` as `hpcadmin` and the password retrieved above. Check that you have a `pbscycle` cluster.
Check that the pbscycle master is well started or wait until it is started, allow about 12 minutes for the master to start.

Manually add few nodes to the cluster.

# Running applications
AzureHPC comes with a set of prebuild application scripts which have been copied over the `/apps` share. We will use this to run some examples.

## Step 1 - Connect to the master
From the machine and directory you have deployed the infrastructure defined above, connec to the master.

```
```

## Step 2 - Check that ANF and NFS shared are mounted

```
[hpcadmin@ip-0A020804 ~]$ df
Filesystem           1K-blocks     Used  Available Use% Mounted on
devtmpfs              16451984        0   16451984   0% /dev
tmpfs                 16463856        0   16463856   0% /dev/shm
tmpfs                 16463856     9264   16454592   1% /run
tmpfs                 16463856        0   16463856   0% /sys/fs/cgroup
/dev/sda2             30416376 10572700   19843676  35% /
/dev/sda1               505580    65552     440028  13% /boot
/dev/sda15              506608    11328     495280   3% /boot/efi
/dev/sdb1             65923564    53276   62498516   1% /mnt/resource
tmpfs                  3292772        0    3292772   0% /run/user/20002
beegfs_nodev         263958528   651264  263307264   1% /beegfs
jumpbox:/share/apps 2146156736    62080 2146094656   1% /apps
jumpbox:/share/data 2146156736    62080 2146094656   1% /data
[hpcadmin@ip-0A020804 ~]
```

Check that the /apps directory contains all the AzureHPC application scripts

```
[hpcadmin@ip-0A020804 ~]$ ls -al /apps
total 20
drwxrwxrwx. 31 root       root       4096 Jun 18 07:59 .
dr-xr-xr-x. 20 root       root       4096 Jun 18 08:34 ..
drwxr-xr-x.  2 cyclecloud cyclecloud   79 Jun 18 07:59 abaqus
drwxr-xr-x.  3 cyclecloud cyclecloud   92 Jun 18 07:59 ansys_mechanical
drwxr-xr-x.  2 cyclecloud cyclecloud  111 Jun 18 07:59 convergecfd
drwxr-xr-x.  2 cyclecloud cyclecloud  102 Jun 18 07:59 fio
drwxr-xr-x.  2 cyclecloud cyclecloud   74 Jun 18 07:59 fluent
drwxr-xr-x.  8 cyclecloud cyclecloud  220 Jun 18 07:57 .git
-rw-r--r--.  1 cyclecloud cyclecloud 5907 Jun 18 07:57 .gitignore
drwxr-xr-x.  2 cyclecloud cyclecloud   72 Jun 18 07:59 gromacs
drwxr-xr-x.  2 cyclecloud cyclecloud  268 Jun 18 07:59 health_checks
drwxr-xr-x.  2 cyclecloud cyclecloud  147 Jun 18 07:59 imb-mpi
drwxr-xr-x.  2 cyclecloud cyclecloud  134 Jun 18 07:59 intersect
drwxr-xr-x.  2 cyclecloud cyclecloud   85 Jun 18 07:59 io500
drwxr-xr-x.  2 cyclecloud cyclecloud   89 Jun 18 07:59 ior
drwxr-xr-x.  2 cyclecloud cyclecloud   78 Jun 18 07:59 lammps
drwxr-xr-x.  2 cyclecloud cyclecloud  102 Jun 18 07:59 linpack
drwxr-xr-x.  2 cyclecloud cyclecloud   82 Jun 18 07:59 namd
drwxr-xr-x.  2 cyclecloud cyclecloud   77 Jun 18 07:59 nwchem
drwxr-xr-x.  4 cyclecloud cyclecloud  235 Jun 18 07:59 openfoam_org
drwxr-xr-x.  2 cyclecloud cyclecloud   72 Jun 18 07:59 openmpi
drwxr-xr-x.  3 cyclecloud cyclecloud  108 Jun 18 07:59 opm
drwxr-xr-x.  2 cyclecloud cyclecloud  112 Jun 18 07:59 osu
drwxr-xr-x.  2 cyclecloud cyclecloud   92 Jun 18 07:59 pamcrash
drwxr-xr-x.  2 cyclecloud cyclecloud   57 Jun 18 07:59 paraview
drwxr-xr-x.  2 cyclecloud cyclecloud  131 Jun 18 07:59 prolb
drwxr-xr-x.  2 cyclecloud cyclecloud  123 Jun 18 07:59 radioss
drwxr-xr-x.  2 cyclecloud cyclecloud   44 Jun 18 07:59 resinsight
drwxr-xr-x.  2 cyclecloud cyclecloud   31 Jun 18 07:59 reveal
drwxr-xr-x.  2 cyclecloud cyclecloud  256 Jun 18 07:59 spack
drwxr-xr-x.  3 cyclecloud cyclecloud  109 Jun 18 07:59 starccm
drwxr-xr-x.  2 cyclecloud cyclecloud 4096 Jun 18 07:59 wrf
[hpcadmin@ip-0A020804 ~]$
```

> NOTE : You should set ownership of the /apps to the hpcadmin user with : `sudo chown -R hpcadmin:hpcadmin /apps`

## Step 3 - Testing storage with IOR
Build IOR with the AzureHPC application script. You have to run in sudo mode as it install additional packages on the master in order to build it.

```
[hpcadmin@ip-0A020804 ~]$ qsub -N build_ior -k oe -j oe -l select=1 -- /apps/ior/build_ior.sh
0.ip-0A020804
[hpcadmin@ip-0A020804 ~]$ qstat
Job id            Name             User              Time Use S Queue
----------------  ---------------- ----------------  -------- - -----
0.ip-0A020804     build_ior        hpcadmin                 0 H workq
```
Check that a new node is provisioned (unless you have already started one manually). Allow 13 minutes for the node to be ready.
Output file will be named `build_ior.o*`

After the build check that you have an `ior` module in `/apps/modulefiles` and IOR binaries in `/apps/ior-<version>`

Run IOR from a compute node by submitting a job

```
[hpcadmin@ip-0A020804 ~]$ qsub -N ior -k oe -j oe -l select=1 -- /apps/ior/ior.sh /beegfs
0.ip-0A020804
[hpcadmin@ip-0A020804 ~]$ qstat
Job id            Name             User              Time Use S Queue
----------------  ---------------- ----------------  -------- - -----
1.ip-0A020804     ior              hpcadmin                 0 Q workq
```
Output file will be named `ior.o*`


## Step 4 - Run latency and bandwidth tests

```
[hpcadmin@ip-0A020804 ~]$ qsub -N pingpong -k oe -j oe -l select=2:ncpus=1:mpiprocs=1,place=scatter:excl -- /apps/imb-mpi/ringpingpong.sh ompi
[hpcadmin@ip-0A020804 ~]$ qsub -N allreduce -k oe -j oe -l select=2:ncpus=60:mpiprocs=60,place=scatter:excl -- /apps/imb-mpi/allreduce.sh impi2018
[hpcadmin@ip-0A020804 ~]$ qsub -N osu -k oe -j oe -l select=2:ncpus=1:mpiprocs=1,place=scatter:excl -- /apps/osu/osu_bw.sh
```
Output files will be named `pingpong.o*, allreduce.o*, osu.o*`

## Step 5 - Build and run HPL

Submit the build, once the job is finish submit the run.
```
[hpcadmin@ip-0A020804 ~] qsub -N build_hpl -k oe -j oe -l select=1:ncpus=1:mpiprocs=1,place=scatter:excl -- /apps/linpack/build_hpl.sh
[hpcadmin@ip-0A020804 ~] qsub -N single_hpl -k oe -j oe -l select=1:ncpus=1:mpiprocs=1,place=scatter:excl -- /apps/linpack/single_hpl.sh
```

Output files will be named `build_hpl.o*, single_hpl.o*`


# Remove all

## Step 1 - Optionally delete the PBS cluster

From your deployment machine run

```
$ cyclecloud terminate_cluster pbscycle
$ cyclecloud delete_cluster pbscycle
```

## Step 2 - Drop all the resources

```
$ azhpc-destroy --no-wait
[2020-06-16 17:25:20] reading config file (config.json)
[2020-06-16 17:25:20] warning: deleting entire resource group (xps-hack)
[2020-06-16 17:25:20] you have 10s to change your mind and ctrl-c!
[2020-06-16 17:25:30] too late!
```
