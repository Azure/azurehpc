# Build a compute cluster with no public IP access, log-on using Azure Bastion

Visualisation: [config.json](https://azurehpc.azureedge.net/o=https://raw.githubusercontent.com/Azure/azurehpc/master/examples/bastion/config.json)

This example will create an HPC cluster wth no public IP, you can log-in using Azure Bastion, from the Portal RDP to a Windows VM or ssh to a linux VM.
>Note: The config_no_pub_ip.json deploys an Azure Bastion, VNET and a jumpbox (no pub IP), then you can login to the jumpbox via the azure bastion and deploy the rest of your azurehpc deployment.

## Initialise the project

To start you need to copy this directory and update the `config.json`.  Azurehpc provides the `azhpc-init` command that can help here by compying the directory and substituting the unset variables.  First run with the `-s` parameter to see which variables need to be set:

```
azhpc-init -c $azhpc_dir/examples/bastion -d bastion -s
```

The variables can be set with the `-v` option where variables are comma separated.  The output from the previous command as a starting point.  The `-d` option is required and will create a new directory name for you.  Please update to whatever `resource_group` you would like to deploy to:

```
azhpc-init -c $azhpc_dir/examples/bastion -d bastion -v resource_group=azurehpc-cluster
```

> Note:  You can still update variables even if they are already set.  For example, in the command below we change the region to `westus2` and the SKU to `Standard_HC44rs`:

```
azhpc-init -c $azhpc_dir/examples/bastion -d bastion -v location=westus2,vm_type=Standard_HC44rs,resource_group=azhpc-cluster
```

## Create the cluster with no public IP

```
cd bastion
azhpc-build
```

Allow ~15 minutes for deployment.  You are able to view the status VMs being deployed by running `azhpc-status` in another terminal.

## Log in the cluster

Connect to the linux headnode using Azure bastion service via ssh

Locate the VM you want to connect to on the Azure portal and check "Connect".

![Alt text](/examples/bastion/images/bastion_connect.JPG?raw=true "Azure Bastion connect")

Click the bastion option and login using your private keys or user/password

![Alt text2](/examples/bastion/images/bastion_ssh.JPG?raw=true "Azure Bastion ssh")

Should now be on your linux headnode

![Alt text3](/examples/bastion/images/bastion_ssh_login.JPG?raw=true "Azure Bastion ssh login")


Similarly, you can use Azure bastion to login to a Windows VM using RDP

![Alt text4](/examples/bastion/images/bastion_rdp_windows.JPG?raw=true "Azure Bastion rdp windows")

