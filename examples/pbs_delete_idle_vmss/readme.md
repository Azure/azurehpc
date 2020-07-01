# Build a PBS compute cluster with automatic deletion of idle VMSS instances

Visualisation: [config.json](https://azurehpc.azureedge.net/?o=https://raw.githubusercontent.com/Azure/azurehpc/master/examples/pbs_delete_idle_vmss/config.json)

This example will create an HPC cluster ready to run with PBS Pro. Idle instances in VMSS's will be automatically deleted and removed from PBS (To control resource costs). The default idle period is 10 minutes (Can be changed in the config file). The idle period measurement does not start when the HPC cluster first comes up, it starts when a PBS job completes on a VMSS instance. The script to check for idle VMSS instances runs at intervals defined in the crontab (crontab -l). A logfile is also generated at /tmp/azurehpc_delete_idle_vmss.log_$$ to help monitor/track/debug idle VMSS instances and record what instances have been deleted.

## Prerequisites

azcli is installed on the headnode and azcli is authorized to delete/create azure resources in the subscription you are using (e.g az login).

## Initialise the project

To start you need to copy this directory and update the `config.json`.  Azurehpc provides the `azhpc-init` command that can help here by compying the directory and substituting the unset variables.  First run with the `-s` parameter to see which variables need to be set:

```
azhpc-init -c $azhpc_dir/examples/pbs_delete_idle_vmss -d pbs_delete_idle_vmss -s
```

The variables can be set with the `-v` option where variables are comma separated.  The output from the previous command as a starting point.  The `-d` option is required and will create a new directory name for you.  Please update to whatever `resource_group` you would like to deploy to:

```
azhpc-init -c $azhpc_dir/examples/pbs_delete_idle_vmss -d pbs_delete_idle_vmss -v resource_group=azurehpc-cluster
```

## Create the cluster 

```
cd pbs_delete_idle_vmss
azhpc-build
```

Allow ~10 minutes for deployment.  You are able to view the status VMs being deployed by running `azhpc-status` in another terminal.


