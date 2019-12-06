# Azure CycleCloud Lustre

Lustre is a High Performance Parallel Filesystem typically used for High Performance Computing.  This repository contains an Azure CycleCloud project and templates to create a lustre file system on Azure.

This Lustre filesystem project is designed for scratch data and uses [Lsv2](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/sizes-storage#lsv2-series) virtual machines that have local NVME disks.  All the NVME disks in the virtual machine will be combined in a RAID 0 and used as the OST.  The MDS virtual machine is also used as an OSS where the local SSD is used for the MDT.  Please consider the [network throughput](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/sizes-storage#lsv2-series) when choosing the VM type as the bottleneck for this setup is the network.  For this reason it is not advisable to go any larger than the L32s_v2 for the MDS/OSS.

The project has an option to use [HSM](https://github.com/edwardsp/lemur) where data can be imported and archived to [Azure BLOB storage](https://azure.microsoft.com/en-gb/services/storage/blobs/).  All nodes run the HSM daemon when enabled.

Monitoring can be enabled where the following metrics will be written to [Log Analytics](https://docs.microsoft.com/en-us/azure/azure-monitor/log-query/get-started-portal#meet-log-analytics):

* Load Average
* Kilobytes Free
* Network Bytes Sent
* Network Bytes Received

The Lustre versions that are currently supported are `2.10` and `2.12`.  Make sure that the filesystem and clients all use the same version.  The [Whamcloud](https://downloads.whamcloud.com/public/lustre/) repository is used for RPMs and so you must use version `2.10` for CentOS 7.6 and `2.12` for CentOS 7.7.

> Note: The Lustre configuration scripts are from [here](https://github.com/Azure/azurehpc/tree/master/scripts).  If the [AzureHPC](https://github.com/Azure/azurehpc) is checked out an installed there is a script, `update_lustre_scripts.sh`, that will update the cycle template with the latest versions.

# Installation

Below are instructions to check out the project from github and add the lfs project and template:

```
git clone https://github.com/edwardsp/cyclecloud-lfs.git
cd cyclecloud-lfs
cyclecloud project upload <container>
cyclecloud import_template -f templates/lfs.txt
```

An extended PBSpro template is included in this repository with the option for choose a Lustre filesystem to set up and mount on the nodes:

```
cyclecloud import_template -f templates/pbspro.txt
```

> Note: The PBSpro template a modified version of the official one [here](https://github.com/Azure/cyclecloud-pbspro/blob/master/templates/pbspro.txt)

Now, you should be able to create a new "lfs" cluster in the Azure CycleCloud User Interface.  Once this has been created you can create PBS cluster and, in the configuration, select the new file system to be used.

# Extending a template to use a Lustre filesystem

The node types only need the following additions:

```
[[[configuration]]]
lustre.cluster_name = $LustreClusterName
lustre.version = $LustreVersion
lustre.mount_point = $LustreMountPoint

[[[cluster-init lfs:client]]]
```

These variables (`LustreClusterName`, `LustreVersion` and `LustreMountPoint`) can be parameterized and given an additional `Lustre Setttings` configuration section by appending the following to the template:

```
[parameters Lustre Settings]
Order = 25
Description = "Use a Lustre cluster as a NAS. Settings for defining the Lustre cluster"

    [[parameter LustreClusterName]]
    Label = Lustre Cluster
    Description = Name of the Lustre cluster to connect to. This cluster should be orchestrated by the same CycleCloud Server
    Required = True
    Config.Plugin = pico.form.QueryDropdown
    Config.Query = select ClusterName as Name from Cloud.Node where Cluster().IsTemplate =!= True && ClusterInitSpecs["lfs:default"] isnt undefined
    Config.SetDefault = false

    [[parameter LustreVersion]]
    Label = Lustre Version
    Description = The Lustre version to use
    DefaultValue = "2.10"
    Config.FreeForm = false
    Config.Plugin = pico.control.AutoCompleteDropdown
        [[[list Config.Entries]]]
        Name = "2.10"
        Label = "2.10"
        [[[list Config.Entries]]]
        Name = "2.12"
        Label = "2.12"
    
    [[parameter LustreMountPoint]]
    Label = Lustre Mount Point
    Description = The mount point to mount the Lustre file server on.
    DefaultValue = /lustre
    Required = True
```

# Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.microsoft.com.

When you submit a pull request, a CLA-bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., label, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.