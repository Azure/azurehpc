# Azure CycleCloud Template for Benchmarking StarCCM

## Pre-requisites:

* An installed and setup Azure CycleCloud Application Server (instructions [here](https://docs.microsoft.com/en-us/azure/cyclecloud/quickstart-install-cyclecloud))
* The Azure CycleCloud CLI (instructions [here](https://docs.microsoft.com/en-us/azure/cyclecloud/install-cyclecloud-cli))

## Overview

This guide will go through the steps required to extend the Azure CycleCloud PBS Pro template ready for installing and running StarCCM benchmarks.

## Creating the cluster in Azure CycleCloud

A few changes to the default PBS project are required:

1. Install `libXt` on all VMs

    This library is required for StarCCM and should be installed through the package manager.

2. Stop the Linux Agent on the execute VMs

    We will stop the Linux Agent on the execute nodes in the cluster as this can impact performance at the large scale for a tightly coupled MPI application when running with all the cores.

3. Export the scratch disk on the master node

    The standard PBS project has an NFS server on the master node but this exports directories from the OS disk associated which is only 30GB in size.  This is sufficient for the StarCCM binaries but the larger StarCCM benchmark would exceed this.  The master will be updated to export the local disk in the VM.  Note: a local disk should only be used for scratch data.

### Creating a project

First make sure you know the name of you Azure CycleCloud locker:

    $ cyclecloud locker list
    azure-storage (az://azurecyclestorage/cyclecloud)

In my setup it is called `azure-storage`.

Now create the project:

    $ cyclecloud project init mycluster
    Project 'mycluster' initialized in /home/paul/cyclecloud-starccm/mycluster
    Default locker: azure-storage

Change to the new project directory to complete the steps that follow:

    cd mycluster

Add a `default` cluster init for the project where we install the StarCCM dependency:

    $ cat <<EOF >>specs/default/cluster-init/scripts/01_install_packages.sh
    #!/bin/bash

    yum -y install libXt
    EOF
    $ chmod +x specs/default/cluster-init/scripts/01_install_packages.sh

We create a new project `spec` to disable the Linux Agent that we can apply to the execute nodes.  Create this as follows:

    $ cyclecloud project add_spec disable-agent
    Spec disable-agent added to project!

Add a script in the cluster init:

    $ cat <<EOF >>specs/disable-agent/cluster-init/scripts/01-disable-agent.sh
    #!/bin/bash

    systemctl stop waagent
    EOF
    $ chmod +x specs/disable-agent/cluster-init/scripts/01-disable-agent.sh

Next, create another `spec` for the master to add a symlink for `/scratch` and change the permissions to allow write access by everyone:

    $ cyclecloud project add_spec scratch-setup
    Spec scratch-setup added to project!

Add the cluster init script:

    $ cat <<EOF >>specs/scratch-setup/cluster-init/scripts/01-scratch-setup.sh
    #!/bin/bash

    chmod a+rwx /mnt/resource
    ln -s /mnt/resource /scratch
    EOF
    $ chmod +x specs/scratch-setup/cluster-init/scripts/01-scratch-setup.sh


Now, upload the project:

    $ cyclecloud project upload
    Uploading to az://azurecyclestorage/cyclecloud/projects/mycluster/1.0.0 (100%)
    Uploading to az://azurecyclestorage/cyclecloud/projects/mycluster/blobs (100%)
    Upload complete!

### Create the template

The PBS template can be used as a basis and updated for the required changes:

    wget https://raw.githubusercontent.com/Azure/cyclecloud-pbspro/master/templates/pbspro.txt

Update the template file with the following changes:

1. Change the template name

    Change the for the top-level section:

        [cluster PBSProCustom]

2. Install `libXt` on all VMs

    Add the following line in section under `[[node defaults]]` and `[[[configuration]]]`:

        [[[cluster-init mycluster:default:1.0.0]]]

3. Stop the Linux Agent on the execute VMs

    Add the following line in the section under `[[nodearray execute]]` and `[[[configuration]]]`:

        [[[cluster-init mycluster:disable-agent:1.0.0]]]

4. NFS Server

    Add the following line in the section under `[[node master]]` and `[[[configuration]]]`:
        
        [[[configuration cyclecloud.exports.nfs_data]]]
        type = nfs
        export_path = /mnt/resource

5. NFS Client

    Add the following line in the section under `[[nodearray execute]]` and `[[[configuration]]]`:

        [[[configuration cyclecloud.exports.nfs_data]]]
        type = nfs
        mountpoint = /scratch
        export_path = /mnt/resource

6. Set up the `scratch` directory on the master

    Add the following line in the section under `[[node master]]` and `[[[configuration]]]`:

        [[[cluster-init mycluster:scratch-setup:1.0.0]]]

Finally, upload the new template:

    $ cyclecloud import_template -f pbspro.txt
    Importing default template in pbsprocustom.txt....
    -------------------------
    PBSProCustom : *template*
    -------------------------
    Resource group:
    Cluster nodes:
        master: Off -- --
    Total nodes: 1

The new template will now show in the Azure CycleCloud webpage.

