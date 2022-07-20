# Deploying a complete (no public IP) NDv4 cluster using Cyclecloud, SLURM, Azure Netapp Files with integrated healthchecks

Here we will explain how to deploy a complete NDv4 Cluster with no public IP access. We use Bastion as the landing zone and from there we 
deploy the complete NDv4 cluster.

The NDv4 cluster will consist of
- NDv4 compute nodes running Ubunt-hpc 18.04, Max GPU app clock frequencies are set, GPU persistent mode is enabled, local NVMe SSD's are mounted.
- Cyclecloud 8.2.2 with SLURM 2.6.4(pmix support) is installed and the pmix libraries are installed on NDv4 nodes.
- Automatic recovery from a reboot enabled (e.g NVMe SSD will be remounted and GPU clock freq reset)
- Premium SSD's used for OS disks, with larger capacity (60GB)
- Accelerated networking is enabled on NDv4
- User home directories are mounted on Azure netapp files
- Extensive automatic pre-job healthchecks are enabled (Unhealthy nodes will be put into a DRAIN state)
- A separate login node (separate from the scheduler is deployed)
- Cyclecloud autoscaling is disabled.
- Option to support containers by adding Nvidia pyxis+enroot SLURM integration
- Windows server (winbox) is deployed to access the Cyclecloud portal via RDP

## Prerequistes
- Bastion and jumpbox is deployed (landing zone), see examples/bastion for an example of how to deploy it.
- Copy experimental/gpu_optimizations/max_gpu_app_clocks.sh to the scripts dir
- Copy experimental/cc_slurm_nhc/cc_slurm_nhc/specs/default/cluster-init/files to the scripts dir
- Copy experimental/cc_slurm_pyxis_enroot/cc_slurm_pyxis_enroot/specs/default/cluster-init/files to the scripts dir (if using the config_pyxis_enroot.json config file)
- The prereqs.json and config.json files are edited (e.g all NOT-SET sections are set).


## Step 1 - Deploy keyvault, VNet+peering, Azure netapp files

We need to first deploy some additional prerequistes for the Cyclecloud deployment, for example keyvault (with passwords), Vnet with peering to the Bastion landing zone  and Azure netapp files. The following is executed from the Bastion landing zone or from the Cloud shell.

```
$ azhpc-build -c prereqs.json
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
