# Build and E2E Shearwater reveal HPC Cluster 

Visualisation: [config.json](https://azurehpc.azureedge.net/?o=https://raw.githubusercontent.com/Azure/azurehpc/master/examples/reveal_E2E/config.json)

This example will create a Shearwater Reveal HPC cluster, including the Reveal application, Headnode, PBS pro, HB120_v2 and ND40rs_v2 compute nodes and a BeeGFS parallel filesystem. 

## Initialise the project

To start you need to copy this directory and update the `config.json`.  Azurehpc provides the `azhpc-init` command that can help here by compying the directory and substituting the unset variables.  First run with the `-s` parameter to see which variables need to be set:

```
azhpc-init -c $azhpc_dir/examples/reveal_E2E -d reveal_E2E -s
```

The variables can be set with the `-v` option where variables are comma separated.  The output from the previous command as a starting point.  The `-d` option is required and will create a new directory name for you.  Please update to whatever `resource_group` you would like to deploy to:

```
azhpc-init -c $azhpc_dir/examples/reveal_E2E -d reveal_E2E -v resource_group=reveal-cluster
```

> Note:  You can still update variables even if they are already set.  For example, in the command below we change the region to `westus2` and the SKU to `Standard_HC44rs`. Use the azurehpc convenient sasurl template to define the location of the reveal tarball (reveal_sas_url), the reveal license file (reveal_license_sas_url) and the azurehpc secret template to define the Azure key vault containing the headnode pasword (headnode_pw). Define gpu_image to be the location of a custom image for ND40rs_v2 sku's (contained nvidia drivers and MOFED)

```
azhpc-init -c $azhpc_dir/examples/reveal_E2E -d reveal_E2E -v location=westus2,vm_type=Standard_HC44rs,resource_group=azhpc-cluster
```

## Create the cluster 

```
cd reveal_E2E
azhpc-build
```

Allow ~20 minutes for deployment.  You are able to view the status VMs being deployed by running `azhpc-status` in another terminal.

## Log in the cluster

Use Remote desktop connection to connect to your headnode using rdp. (Use the Public IP of your headnode, "hpcuser" as log in name and the headnode password you set 
in the Azure keyvault.

