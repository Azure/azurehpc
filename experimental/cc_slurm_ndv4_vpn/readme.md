# Deploy an NDv4 cluster using Cyclecloud, SLURM, and Azure Netapp Files with integrated healthchecks using a VPN connection to Azure without a public IP

Here we will explain how to deploy a complete NDv4 Cluster with no public IP access assuming an existing VPN and jumpbox derived from the `deploy_cycle_slurm_ndv4` workflow.

The NDv4 cluster will be configured with:
- NDv4 compute nodes running Ubuntu-hpc 18.04, max GPU applicaton clock frequencies are set, GPU persistent mode is enabled, and local NVMe SSDs are mounted
- Cyclecloud 8.2.2 with SLURM 2.6.4 with pmix support is installed with the appropriate pmix libraries installed on NDv4 nodes
- Automatic recovery from a reboot enabled (i.e. NVMe SSD will be remounted and GPU clock freq reset)
- Premium 60 GB SSDs used for OS disks
- Accelerated networking is enabled on NDv4
- User home directories are mounted on Azure netapp files
- Extensive automatic pre-job healthchecks are enabled (Unhealthy nodes will be put into a DRAIN state)
- A separate login node (separate from the scheduler is deployed)
- CycleCloud autoscaling disabled
- Option to support containers by adding NVIDIA [pyxis](https://github.com/NVIDIA/pyxis) + [enroot](https://github.com/NVIDIA/enroot) SLURM integration

## Prerequistes
- Ensure a VPN and keyvault already exist
- Ensure azhpc has been installed

## Step 1 - Prepare for deployment
- Edit and source `.envrc-template` to populate environmental variables used to define deployment configuration variables.
- Run `setup.sh` to copy scripts required for deployment. Copies max_gpu_app_clocks.sh, node health check (NHC) scripts, and `pyxis` and `enroot` scripts to run Docker containers on SLURM.
    - NOTE: `setup.sh` uses environmental variable `OUTPUT_DIR` defined in `.envrc-template`.

## Step 2 - Deploy new keyvault, VNet + peering, and Azure NetApp Files

Populate variables in `prereqs.json`, move to deployment directory ($OUTPUT_DIR in `.envrc-template`), and deploy (`build`).

Note, if you actively connected to the VPN the connection will drop, but you can immediately reconnect.

```bash
azhpc-init -c prereqs.json
pushd $OUTPUT_DIR
azhpc-build -c preqs.json
popd
```

## Step 3 - Deploy CycleCloud

Populate variables in `config.json`, move to deployment directory, and deploy (`build`).

```bash
azhpc-init -c config.json
pushd $OUTPUD_DIR
azhpc-build -c config.json --no-vnet
popd
```

*Alternatively*, you can run the `deploy-cc.sh` script to perform Step 1, Step 2, and Step 3.

## Step 4 - Start the cluster in CycleCloud

### Slurm

To start the Slurm cluster:

```bash
cyclecloud start_cluster slurmcycle
```

Retrieve the cluster status by running:

```bash
cyclecloud show_cluster slurmcycle | grep server | xargs | cut -d ' ' -f 2
cyclecloud show_nodes -c slurmcycle --format=json | jq -r '.[0].State'
```

You can also start the cluster from the CycleCloud Portal through the CycleServer webapp by connecting via
a browser to the IP obtained in *Step 4*.


## Step 4 - Connect to CycleServer UI

Retrieve the CycleServer IP and password with the `azhpc-get` command

```bash
$ azhpc-get ip.cycleserver
ip.cycleserver = 10.40.1.4
```

Retrieve the CycleCloud admin password:

```bash
azhpc-get "secret.{{variables.key_vault}}.{{variables.cc_password_secret_name}}"
```

Open the CycleCloud webapp at `ip cycleserver` as `hpcadmin` with the password retrieved above. Ensure that the cluster `slurmcycle` exists and has either started or is starting.

## Step 5 - Connect to the login node (login-1)


Connect to the CycleCloud login node (login-1).

```bash
cyclecloud connect login-1 -k <path/to/hpcadmin_id_rsa> -c slurmcycle
```

## Step 6 - To deploy(allocate) NDv4 nodes

From the scheduler or login node

```bash
sudo /opt/cycle/slurm/resume_program.sh <node_list>
```

## Step 7 - To delete(deallocate) NDv4 nodes

From the scheduler or login node

```bash
sudo /opt/cycle/slurm/suspend_program.sh <node_list>
```

# Remove all

## Step 1 - Optionally delete the Slurm cluster

From your deployment machine run

```bash
cyclecloud terminate_cluster <cluster_name>
cyclecloud delete_cluster <cluster_name>
```

## Step 2 - Drop all the resources

```bash
$ azhpc-destroy --no-wait
[2020-06-16 17:25:20] reading config file (config.json)
[2020-06-16 17:25:20] warning: deleting entire resource group (xps-hack)
[2020-06-16 17:25:20] you have 10s to change your mind and ctrl-c!
[2020-06-16 17:25:30] too late!
```