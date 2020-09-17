# Building Blocks
This directory contains reusable configuration file building blocks which can be used with the `init-and-merge.sh` script to produce a unique config file. The variables have been named to avoid collision with other blocks. Most blocks assume that a VNET exists (hence the dependency on the `vnet.json` block) and being installed from a jumpbox. 


## Block list

| Name                                          | Description                                                                                          | Dependency on         |
|-----------------------------------------------|------------------------------------------------------------------------------------------------------|-----------------------|
| **ad.json**                                   | Create an AD Directory Services VM named ADDS with domain hpc.local                                  | `vnet`, `jumpbox`     |
| **anf.json**                                  | Create a Premium 4TB volume with 2x2TB pools `/data` and `/apps`                                     | `vnet`                |
| **anf-smb.json**                              | Create a Premium 4TB SMB volume with 4TB pool `/data`                                                | `ad`, `vnet`          |
| **beegfs-cluster.json**                       | Create BeeGFS cluster                                                                                | `jumpbox`, `vnet`     |
| **cycle-cli-jumpbox.json**                    | Install the CycleCloud CLI on the jumpbox                                                            | `cycle-prereqs-managed-identity`, `vnet` |
| **cycle-cli-local.json**                      | Install the CycleCloud CLI locally                                                                   | `cycle-prereqs-managed-identity`, `vnet` |
| **cycle-install-server-managed-identity.json**| Create a CycleCloud server in a managed identity context                                             | `cycle-prereqs-managed-identity`, `jumpbox`, `vnet`|
| **cycle-prereqs-managed-identity.json**       | Create all pre-requisites for deploying CycleCloud with managed identity                             |                       |
| **jumpbox.json**                              | Create a jumpbox in the admin subnet                                                                 | Existence of a VNET   |
| **jumpbox-anf.json**                          | Create a jumpbox in the admin subnet with ANF mounted                                                | `anf`                 |
| **jumpbox-nfs.json**                          | Create a jumpbox in the admin subnet acting as a 2TB NFS server                                      | Existence of a VNET   |
| **vnet.json**                                 | Create a vnet named `hpcvnet` 10.2.0.0/20 with subnets admin, compute, netapp, viz and storage       |                       |
| **workstation.json**                          | Build a Windows Desktop workstation, domain joined                                                   | `ad`                  |



## How to use building blocks ?
It's easy as the blocks have been designed to be merged together into a single configuration file. The `init-and-merge.sh` will do the merge and initialization and you just need to provide an ordered list of the blocks you want to use and json file containing the variables you want to set. 
The `init.sh` script below will create a config file to deploy a VNET, a JUMPBOX with NFS and a BEEGFS cluster.

```
#/bin/bash
block_dir=$azhpc_dir/blocks
AZHPC_CONFIG=config.json
AZHPC_VARIABLES=variables.json

blocks="$block_dir/vnet.json $block_dir/jumpbox-nfs.json $block_dir/beegfs-cluster.json"

# Initialize config file
echo "{}" >$AZHPC_CONFIG
$azhpc_dir/init-and-merge.sh "$blocks" $AZHPC_CONFIG $AZHPC_VARIABLES
```

Before running that script I need to create a `variables.json` file which contains all the `<NOT-SET>` values of my blocks. In our case these are only `resource_group` and `location`.
```json
{
  "variables": {
    "resource_group": "my resource group",
    "location": "my location"
  }
}
```

Once done I can run the init script wich produce a config.json that I can use to build my whole environment.

```
$ ./init.sh
$ azhpc-build
```

> NOTE : Have a look at the examples/cc_beegfs directory for a detailed example
