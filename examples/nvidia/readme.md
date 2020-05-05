# Deploy a GPU VM instance
![Build Status](https://azurecat.visualstudio.com/hpccat/_apis/build/status/azhpc/examples/nvidia?branchName=master)

This example shows how to build a GPU instance that can be used as a based image for future deployments.


The configuration file requires the following variables to be set:

| Variable                | Description                                  |
|-------------------------|----------------------------------------------|
| location                | The location of resources                    |
| resource_group          | The resource group for the project           |
| vm_type                 | Azure GPU VM full name (NC or ND series)     |

