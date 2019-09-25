# AzureHPC

## Overview

This project is aimed at simplifiying deployment and setup for HPC environments in Azure.  The deployment scripts include setting up various building blocks available for Networking, Compute and Storage that are needed for an e2e setup. You can do this all with a few commands and fast as these are run in parallel. 

They key motivation is:

* __Simplified Automation__
* Flexibility
* Speed of deployment

The basis for the project is a single JSON config file and some shell scripts for installing.  The key point about the config file is that you can describe network, resources and installation steps.  Tags are applied to resources that determines which resources run each install step.

The `azhpc_*` scripts only require the azure cli and a few utilities (bash, jq and ssh).

All of this is available in the Cloud Shell.  Alternatively you can run on a Linux VM on Azure or from the Windows Ubuntu Shell.

Multiple [examples](https://github.com/Azure/azurehpc/tree/master/examples) for building blocks commonly used, scripts for building, installing and running [some applications](https://github.com/Azure/azurehpc/tree/master/apps) are included here so they can be used as you build your environment and run benchmarks.

We have also made [some tutorials](https://github.com/Azure/azurehpc/tree/master/tutorials) available that you can follow to not only learn more about the framework but also to understand how you can easily set an environment up e2e for your own application.

## JSON configuration file

The JSON file is composed of the following:

* Variables dictionary
* Setup information
* Network dictionary
* Resources dictionary
* Install list

### Variables dictionary

This allows variables to be created and used throughout the config file (see how this works [here](#macros-in-the-config-file).  This can be used when creating a template for others to use or just when the same value is repeated for many resources, e.g. choosing the OS image.

> When creating templates for others to use the value should be `<NOT-SET>` so the `azhpc-*` commands will notify the user.

### Setup information

The following information is required:

| Name           | Description                                       |
|----------------|---------------------------------------------------|
| location       | The region where the resources are created        |
| resource_group | The resource group to put the resources           |
| install_from   | The resource where the install script will be run |
| admin_user     | The admin user for all resources                  |

The `azhpc-build` command will generate an install script from the configuration file.  This will be run from the `install_from` VM.  The `install_from` VM must either have a public IP address or be accessible by hostname from where `azhpc-build` is run (i.e. run `azhpc-build` from a VM on the same vnet).

### Network dictionary

The config file will create vnets and subnets from the config file.

| Name           | Description                                                                        |
|----------------|------------------------------------------------------------------------------------|
| resource_group | This can be used if different to the resources                                     |
| name           | Vnet name                                                                          |
| address_prefix | The address prefix (CIDR notation)                                                 |
| subnets        | Dictionary containing key-values for `<subnet-name>` and `<subnet-address-prefix>` |

Here is an example setup with four subnets:

```
...
"vnet": {
    "resource_group": "vnet-resource-group",
    "name": "hpcvnet",
    "address_prefix": "10.2.0.0/20",
    "subnets": {
        "admin": "10.2.1.0/24",
        "viz": "10.2.2.0/24",
        "storage": "10.2.3.0/24",
        "compute": "10.2.4.0/22"
    }
},
...
```

> Note: If the vnets/subnets exist it will use what it already there.

### Resources dictionary

This dictionary describes the resources for the project.

| Name                   | Description                                                             |
|------------------------|-------------------------------------------------------------------------|
| type                   | The resource type, either "vm" or "vmss" is currently supported         |
| vm_type                | The Azure VM SKU to use for the resource                                |
| public_ip              | Boolean flag for whether to use a public IP (default: false)            |
| accelerated_networking | Boolean flag for whether to use accelerated networking (default: false) |
| image                  | The OS image to use                                                     |
| subnet                 | The subnet to place the resource in                                     |
| instances              | The number of instances (**vmss only**)                                 |
| low_priority           | Boolean flag for low priority (**vmss only**)                           |
| tags                   | A list of strings with the tags for the resource                        |

### Install list

This describes the steps to install after all the resources have been provisioned.  An install script is created from the list which is run on the `install_from` VM.  Each step is a dictionary containing the following:

| Name   | Description                                                                                                                                                |
|--------|------------------------------------------------------------------------------------------------------------------------------------------------------------|
| script | The name of the script to run                                                                                                                              |
| tag    | The tag to select which resources will run this step                                                                                                       |
| sudo   | Boolean flag for whether to run the script with sudo                                                                                                       |
| args   | A list containing the arguments for the script (default: false)                                                                                            |
| copy   | This is a list of files to copy to each resource from the `install_from` VM and assumes the file will have been downloaded as a previous step (*optional*) |

> Note: the script to run be the path relative to either the `$azhpc_dir/scripts` or a local `scripts` directory for the project.  The local directory will take precedence over the `$azhpc_dir/scripts`.  


### Macros in the config file

For the most part the configuration is just a standard JSON file although there are a few translations that can take place:

#### Variables

If a value is prefixed with `variables.` then it will take the value from the proceeding JSON path under the variables section.  For example:

```
{
    "location": "variables.location",
    ...
    "variables": {
        "location": "westus2"
    },
    ...
}
```

In the example above, the location will be taken from `variables.location`.

#### Secrets

The scripts allow secrets to be stored in keyvault.  To read from keyvault use the following format: `secret.<KEY-VAULT>.<KEY-NAME>`.

> Note: this assumes the key vault is set up and the key is already stored there.

#### Storage

The config file can create a URL with a SAS key for a file in storage.  This is the format: `sasurl.<STORAGE-ACCOUNT>.<STORAGE-PATH>`.

> Note: the `<STORAGE-PATH>` should start at the container (and *do not have a preceeding `/`*)

## Commands

To set up the environment you first need to _source_ `$azhpc_dir/install.sh`.  This is only required once and will create a `bin` directory with all the commands.  It will also set the `PATH` for the current session (and so there is no issue in running multiple times but you may prefer to just add the `bin` directory to your bashrc).

### azhpc-build

This will build you complete setup from the configuration file.

Usage:

    azhpc-build [options]

| Option        | Short | Description                                    |
|---------------|:-----:|------------------------------------------------|
| --help        | -h    | Display help message                           |
| --config FILE | -c    | The config file to use (default: config.json)  |


### azhpc-connect

This will connect to a node in a running cluster.

Usage:

    azhpc-connect [options] resource

The resource can be any of the resource names in the config file or the actual hostname.  If a VMSS is chosen this will default to the first VM in the scale set.

| Option        | Short | Description                                    |
|---------------|:-----:|------------------------------------------------|
| --help        | -h    | Display help message                           |
| --config FILE | -c    | The config file to use (default: config.json)  |
| --user USER   | -u    | The user to connect as (default: <admin-user>) |

### azhpc-init

This utility initialises a new project and can set variables in the config file.  The config argument can be a file or a directory where the contents are copied to the new project directory.  If a directory is chosen then all files will be copied and any json files will have the variables replaced.

The `-s` option can be used to search for any variables with are `<NOT-SET>` in a config file.  The output will be a string with the `-v` option containing all the variables to set.

Usage:

    azhpc-init [options]

| Option            | Short | Description                                       |
|-------------------|:-----:|---------------------------------------------------|
| --help            | -h    | Display help message                              |
| --config DIR/FILE | -c    | The config file to use (default: config.json)     |
| --dir DIR         | -d    | The output directory for the new project          |
| --vars VAR=VAL    | -v    | The variables to replace (multiple with commas)   |
| --show            | -s    | Show all variables that are not set in the config |

### azhpc-resize

This should be used on a running setup where you can resize an existing VMSS.  After the VMSS has been resized an install script will be generated and run on any new VMs.

Usage:

    azhpc-resize [options] <vmss-resource> <size>

| Option         | Short | Description                                   |
|----------------|:-----:|-----------------------------------------------|
| --help         | -h    | Display help message                          |
| --config FILE  | -c    | The config file to use (default: config.json) |

> Note: some manual interventions may be required to keep you set up in good order.  For example, this will not remove nodes from a PBS cluster when scaling down.

### azhpc-run

This is a utility to run a command on one or more resource.  Behind the scenes it uses the `pssh` command.

Usage:

    azhpc-run [options] command

| Option         | Short | Description                                                                                       |
|----------------|:-----:|---------------------------------------------------------------------------------------------------|
| --help         | -h    | Display help message                                                                              |
| --config FILE  | -c    | The config file to use (default: config.json)                                                     |
| --user USER    | -u    | The user to run as (default: <admin-user>)                                                        |
| --nodes NODES  | -n    | The list of nodes (space separated) which can be resources or hostnames (default: <install_from>) |

### azhpc-scp

This uses the scp to copy a file (or directory if `-r` is added) to/from the remote resource.  The resource hostname should be used.

Usage:

    azhpc-scp [options] resource

| Option        | Short | Description                                   |
|---------------|:-----:|-----------------------------------------------|
| --help        | -h    | Display help message                          |
| --config FILE | -c    | The config file to use (default: config.json) |

### azhpc-status

This is a utility to show the uptime for all the resources in the project

Usage:

    azhpc-status [options]

| Option        | Short | Description                                   |
|---------------|:-----:|-----------------------------------------------|
| --help        | -h    | Display help message                          |
| --config FILE | -c    | The config file to use (default: config.json) |

### azhpc-watch

This shows the provisioning state of all the resources in the project.  If the `-u` option is used this will update for the specified interval time.

Usage:

    azhpc-watch [options]

| Option           | Short | Description                                                   |
|------------------|:-----:|---------------------------------------------------------------|
| --help           | -h    | Display help message                                          |
| --config FILE    | -c    | The config file to use (default: config.json)                 |
| --update SECONDS | -u    | The update time in seconds where 0 is no updates (default: 0) |

## HOWTO

### Setting up Azure Key Vault


This is the command to create a Key Vault:

```
az keyvault create --name <keyvault-name> --resource-group <my-resource-group>
``` 

This is how you can add a secret:

```
az keyvault secret set --vault-name <keyvault-name> --name "<secret-name>" --value "<secret-vault>"
```

This can be accessed in the config file using the following value: 

    secret.<keyvault-name>.<secret-name>


# Windows Subsystem for Linux

The private key needs to have access rights of 0600; when using WSL on the NTFS drive (c: drive); that is by default not allowed. To get this working: add the metadata option to the mount:

```
sudo umount /mnt/c
sudo mount -t drvfs C: /mnt/c -o metadata
```

# Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
