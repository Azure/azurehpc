# Deploying a complete (no public IP) NDv4 cluster using Cyclecloud, SLURM, Azure Netapp Files with integrated healthchecks

Here we will explain how to deploy a complete NDv4 Cluster with no public IP access. We use Bastion as the landing zone and from there we 
deploy the complete NDv4 cluster.

The NDv4 cluster will consist of
- NDv4 compute nodes running Ubunt-hpc 18.04, Max GPU app clock frequencies are set, GPU persistent mode is enabled, local NVMe SSD's are mounted.
- Cyclecloud 8.2.2 with SLURM 2.6.4(pmix support) is installed and the pmix libraries are installed on NDv4 nodes.
- Automatic recovery from a reboot enabled (e.g NVMe SSD will be remounted and GPU clock freq reset)
- Premium SSD's used for OS disks, with larger capacity (60GB)
- Accelerated networking is enabled on NDv4
- User home directories are mounted on Azure netapp files (sunrpc kernel parameter tcp_max_slot_table_entries=128)
- Extensive automatic pre-job healthchecks are enabled (Unhealthy nodes will be put into a DRAIN state)
- A separate login node (separate from the scheduler is deployed)
- Cyclecloud autoscaling is disabled.
- Option to support containers by adding Nvidia pyxis+enroot SLURM integration
- Windows server (winbox) is deployed to access the Cyclecloud portal via RDP
- Deploy MariaDB, access it via a private endpoint and set-up SLURM accounting
- GPU Monitoring (using custom Azure log analytics), DCGMI GPU filed Ids, IB metrics

## Prerequistes
- Bastion and jumpbox is deployed (landing zone), see examples/bastion for an example of how to deploy it.
- Copy experimental/gpu_optimizations/max_gpu_app_clocks.sh to the scripts dir
- Copy experimental/cc_slurm_nhc/cc_slurm_nhc/specs/default/cluster-init/files to the scripts dir (except prolog.sh)
- Copy experimental/cc_slurm_pyxis_enroot/cc_slurm_pyxis_enroot/specs/default/cluster-init/files to the scripts dir (if using the config_pyxis_enroot.json config file)
- Copy experimental/gpu_monitoring/gpu_data_collector.py to the scripts dir (if want to enable GPU Monitoring, using the config_pyxis_enroot_sacct_gpu_monitoring.json config file)
- The appropriate prereqs\*.json and config.json files are edited (e.g all NOT-SET sections are set).


## Step 1a - Deploy Azure log analytics workspace (Only required if you plan on enabling GPU Monitoring)

```
azhpc-build --no-vnet -c prereqs_la_ws.json
```
>Note: We need to deploy the log analytics workspace first, so we can add the secret key and workspace Id to the keyvault (in the next step)

## Step 1b - Deploy keyvault, VNet+peering, Azure netapp files

We need to first deploy some additional prerequistes for the Cyclecloud deployment, for example keyvault (with passwords), Vnet with peering to the Bastion landing zone  and Azure netapp files. The following is executed from the Bastion landing zone or from the Cloud shell.

```
$ azhpc-build -c prereqs.json
```
>Note: If GPU monitoring is to be enabled, the values for the log analytics workspace secret key and workspace ID can be found in the Azure portal log analytics workspace (Agents management --> Log Analytics agent instructions)

## Step 1c - Deploy Maria DB (Only needed if you want to enable Slurm accounting)

```
$ azhpc-build --no-vnet -c prereqs_sacct.json
```

## Step 2 - Deploy NDv4 cluster with Cyclcloud

Now deploy the rest of the infrastructure, This needs to be executed from the Bastion landing zone.

```
$ azhpc-build --no-vnet 
```
>Note: This deployment will not have container support integrated with SLURM (pyxis+enroot)

To deploy with container support integrated with SLURM use the config_pyxis_enroot.json configuration file.
```
azhpc-build --no-vnet -c config_pyxis_enroot.json
```
To deploy with Slurm accounting enabled using a MariaDB
```
azhpc-build --no-vnet -c config_pyxis_enroot_sacct.json
```
>Note: if you wish to also enable GPU monitoring, then use the config_pyxis_enroot_sacct_gpu_monitoring.json configuration file.


## Step 3 - Start the cluster in CycleCloud

### Slurm

To start the Slurm cluster:

```
$ cyclecloud start_cluster slurmcycle
```
>Note: You can also start the cluster from the cyclecloud portal(Accessed via the winbox)

Retrieve the cluster status by running:

```
$ cyclecloud show_cluster slurmcycle | grep server | xargs | cut -d ' ' -f 2
$ cyclecloud show_nodes -c slurmcycle --format=json | jq -r '.[0].State'
```

---

## Step 4 - Connect to CycleServer UI

Retrieve the winbox and CycleServer IPs and password with the `azhpc-get` command

```
$ azhpc-get ip.cycleserver
ip.cycleserver = 10.20.1.5
```
>Note: Similarly for the winbox

Retrieve the CycleCloud admin password:

```
$ azhpc-get "secret.{{variables.key_vault}}.{{variables.cc_password_secret_name}}"
```
>Note: Similarly for the winbox
Login to winbox via Bastion using the retrieved IP and password.

From the winbox connect to the CycleCloud Web Portal `ip cycleserver` as `hpcadmin` with the password retrieved above. Check that you have a `slurmcycle` cluster.
Check that the cluster master is well started or wait until it is started. 


## Step 5 - Connect to the login node (login-1)

From the bastion landing zone  you have deployed the infrastructure defined above, connect to the jumpbox.

```
$ azhpc-connect jumpbox
[2020-07-09 12:55:09] logging directly into jumpbox5f282f.westeurope.cloudapp.azure.com
Last login: Thu Jul  9 10:45:42 2020 from <home>
```

From the jumpbox, connect to the CycleCloud login node (login-1):

### Slurm

```
[hpcadmin@jumpbox ~]$ cyclecloud connect login-1 -c slurmcycle
```

---

## Step 6 - To deploy(allocate) NDv4 nodes

From the scheduler or login node

```
sudo /opt/cycle/slurm/resume_program.sh <node_list>
```

## Step 7 - To delete(deallocate) NDv4 nodes

From the scheduler or login node

```
sudo /opt/cycle/slurm/suspend_program.sh <node_list>
```

# Remove all

## Step 1 - Optionally delete the Slurm cluster

From your deployment machine run

```
$ cyclecloud terminate_cluster <cluster_name>
$ cyclecloud delete_cluster <cluster_name>
```

## Step 2 - Drop all the resources

```
$ azhpc-destroy --no-wait
[2020-06-16 17:25:20] reading config file (config.json)
[2020-06-16 17:25:20] warning: deleting entire resource group (xps-hack)
[2020-06-16 17:25:20] you have 10s to change your mind and ctrl-c!
[2020-06-16 17:25:30] too late!
```

# Some useful SLURM customizations

## Set up priority queues with job preemption capability
Set up multiple job partitions sharing the compute node resources, with different priorities, so jobs in the higher priority partitions can preempt 
jobs in the lower priority partitions. In this example the partions from highest to lowest priority are hpc-high, hpc-mod (default) and hpc-low.

Add the following to the slurm.conf and execute scontrol reconfigure.

```
SuspendExcParts=hpc,hpc-high,hpc-mid,hpc-low
PreemptType=preempt/partition_prio
PreemptMode=REQUEUE
PreemptExemptTime=-1
JobRequeue=1
PartitionName=hpc-high Nodes=cluster02-hpc-pg0-[1-76] PriorityTier=65500 Default=NO DefMemPerCPU=18880 MaxTime=INFINITE State=UP
PartitionName=hpc-mid Nodes=cluster02-hpc-pg0-[1-76] PriorityTier=32766 Default=YES DefMemPerCPU=18880 MaxTime=INFINITE State=UP
PartitionName=hpc-low Nodes=cluster02-hpc-pg0-[1-76] PriorityTier=1 Default=NO DefMemPerCPU=18880 MaxTime=INFINITE State=UP
```

## Set up a quota limit on total number of nodes that can be allocated
It is sometimes desirable to always leave a few nodes idle, so when a job fails due to an unhealthy node the job can be immediately restarted using one of the warm buffer nodes. The following modifications leverage the prologslurmctld to check if the total allocated node threshold will be exceeded, if that is the case then the job is requeued until there are sufficient nodes to run the job but not to exceed the threshold.

In slurm.conf add location to prologslurmctld script

```
PrologSlurmctld=/sched/scripts/prologslurmctld.sh
```

Create directory for prologslurmctld logs

```
sudo mkdir /sched/logs
sudo chmod 777 /sched/logs
```

The prologslurmctld.sh is located this dir.
>Note: You will need to modify ALLOCATED_NODES_THRESHOLD

To prevent the epilog.sh (from NHC) from running NHC when a job is requeued due to exceeding the compute node quota, replace the NHC epilog.sh with the one 
in scripts/epilog.sh.

## Notes on GPU Monitoring

* You can stop the GPU monitoring service
```
sudo systemctl stop gpu_monitoring
```

* You can start the GPU monitoring service
```
sudo systemctl start gpu_monitoring
```

* Check that it is running ok
```
sudo systemctl status gpu_monitoring
```

* To change the GPU Monitoring environment (e.g. What metrics are monitored and at what time interval)
  * Edit /opt/gpu_monitoring/gpu_data_collector.sh
>Note: By default GPU utilization, GPU memory used, tensor cores active, IB data transmitted/received, Slurm JobID and physical hostname metrics, collected and the time interval is 10 seconds and only nodes with Slurm jobs running.
