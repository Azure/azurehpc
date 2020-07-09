# Building the infrastructure

Here we will explain how to deploy a full system with a VNET, JUMPBOX, CYCLESERVER and ANF by using building blocks.

## Step 1 - Install azhpc

Clone the `azhpc` repository and source the `install.sh` script.

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

Then copy the `init.sh` and `variables.json` from `examples/cc_anf` to your working directory.

```
$ cp $azhpc_dir/examples/cc_anf/init.sh .
$ cp $azhpc_dir/examples/cc_anf/variables.json .
```

Edit `variables.json` to match your environment. Give a unique value to `uuid`. An existing keyvault can be referenced if needed.

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

Run the `init.sh` script which will copy all the config files of the building blocks and initialize the variables by using the `variables.json` updated above.

```
$ ./init.sh
```

## Step 2 - Build the system

The first command will create the required pre-requisites for CycleCloud like a Key Vault, generate a password and store it in the Vault.
The second command will build all the resources and create a Slurm cluster.

```
$ azhpc-build --no-vnet -c prereqs.json
$ azhpc-build 
```

The build process should take about 13 minutes.

## Step 3 - Upload application scripts

Upload the AzureHPC application scripts onto the `/apps` share created on the jumpbox. These scripts will be used from the master and compute nodes provisioned by CycleCloud.

```
$ azhpc-scp -- -r $azhpc_dir/apps/. hpcadmin@jumpbox:/apps
```

## Step 4 - Start the cluster in CycleCloud

To Start the Slurm cluster attached to ANF:

```
$ cyclecloud start_cluster slurmcycle
```

Retrieve the cluster status by running:

```
$ cyclecloud show_cluster slurmcycle | grep master | xargs | cut -d ' ' -f 2
$ cyclecloud show_nodes -c slurmcycle --format=json | jq -r '.[0].State'
```

## Step 5 - Connect to CycleServer UI

Retrieve the CycleServer DNS name from the azure portal.

Retrieve the CycleCloud admin password from the logs:

```
$ grep password azhpc_install_config/install/*.log
```

Connect to the CycleCloud Web Portal `https://fqdn-of-cycleserver` as `hpcadmin` with the password retrieved above. Check that you have a `slurmcycle` cluster.
Check that the cluster master is well started or wait until it is started. Allow about 12 minutes for the master to start.

Manually add few nodes to the cluster.

# Running applications

AzureHPC comes with a set of prebuild application scripts which have been copied over the `/apps` share. We will use this to run some examples.

## Step 1 - Connect to the master

From the machine and directory you have deployed the infrastructure defined above, connect to the jumpbox.

```
$ azhpc-connect jumpbox
```

From the jumpbox, connect to the CycleCloud master:

```
[hpcadmin@jumpbox ~]$ cyclecloud connect master -c slurmcycle
```

## Step 2 - Check that ANF shares are mounted

```
[hpcadmin@ip-0A020804 ~]$ df
Filesystem             1K-blocks     Used    Available Use% Mounted on
/dev/sda2               30416376 10336132     20080244  34% /
devtmpfs                16461132        0     16461132   0% /dev
tmpfs                   16472952        0     16472952   0% /dev/shm
tmpfs                   16472952     9372     16463580   1% /run
tmpfs                   16472952        0     16472952   0% /sys/fs/cgroup
/dev/sda1                 505580    65516       440064  13% /boot
/dev/sda15                506608    11400       495208   3% /boot/efi
/dev/sdb1               65923564  2150432     60401360   4% /mnt/resource
tmpfs                    3294592        0      3294592   0% /run/user/1000
10.2.2.4:/azhpcdata 107374182400      320 107374182080   1% /data
10.2.2.4:/azhpcapps 107374182400     1152 107374181248   1% /apps
tmpfs                    3294592        0      3294592   0% /run/user/20002
```

Check that the `/apps` directory contains all the AzureHPC application scripts

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
```

> NOTE : You should set ownership of the `/apps` to the `hpcadmin` user with : `sudo chown -R hpcadmin:hpcadmin /apps`

## Step 3 - Testing storage with IOR

Build IOR with the AzureHPC application script. You have to run in sudo mode as it install additional packages on the master in order to build it.

Check that a new node is provisioned (unless you have already started one manually). Allow 13 minutes for the node to be ready.

```
[hpcadmin@ip-0A020804 ~]$ sbatch -J build_ior -o build_ior.o%A /apps/ior/build_ior.sh
[hpcadmin@ip-0A020804 ~]$ squeue
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
                 1       hpc build_io hpcadmin CF       0:00      1 hpc-pg0-1
```

The build output file will be named `build_ior.o<jobid>`

After the build, check that you have an `ior` module in `/apps/modulefiles` and IOR binaries in `/apps/ior-<version>`

Run IOR from a compute node by submitting a job

```
[hpcadmin@ip-0A020804 ~]$ sbatch -N 1 --exclusive -o ior.o%A -J ior /apps/ior/ior.sh /data
[hpcadmin@ip-0A020804 ~]$ squeue
            JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
                 2       hpc    ior  hpcadmin CF       0:00      1 hpc-pg0-1
```
Output file will be named `ior.o<jobid>`

## Step 4 - Run latency and bandwidth tests

```
[hpcadmin@ip-0A020804 ~]$ sbatch -N 2 --tasks-per-node=1 -J pingpong -o pingpong.o%A /apps/imb-mpi/ringpingpong.sh ompi
[hpcadmin@ip-0A020804 ~]$ sbatch -N 2 --exclusive -o allreduce.o%A -J allreduce /apps/imb-mpi/allreduce.sh impi2018
[hpcadmin@ip-0A020804 ~]$ sbatch -N 2 --tasks-per-node=1 -o osu.o%A -J osu /apps/osu/osu_bw.slurm
```

Output files will be named `pingpong.o<jobid>, allreduce.o<jobid>, osu.o<jobid>`

## Step 5 - Build and run HPL

Submit the build, once the job is finish submit the run.

```
[hpcadmin@ip-0A020804 ~]$ sbatch -J build_hpl -o build_hpl.o%A /apps/linpack/build_hpl.sh
[hpcadmin@ip-0A020804 ~]$ sbatch -N 1 --exclusive -J hpl -o single_hpl.o%A /apps/linpack/single_hpl.sh
```

Output files will be named `build_hpl.o<jobid>, single_hpl.o<jobid>`

# Remove all

## Step 1 - Optionally delete the Slurm cluster

From your deployment machine run

```
$ cyclecloud terminate_cluster slurmcycle
$ cyclecloud delete_cluster slurmcycle
```

## Step 2 - Drop all the resources

```
$ azhpc-destroy --no-wait
[2020-06-16 17:25:20] reading config file (config.json)
[2020-06-16 17:25:20] warning: deleting entire resource group (xps-hack)
[2020-06-16 17:25:20] you have 10s to change your mind and ctrl-c!
[2020-06-16 17:25:30] too late!
```
