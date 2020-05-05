== Managed Identity
![Build Status](https://azurecat.visualstudio.com/hpccat/_apis/build/status/azhpc/examples/managed_identity?branchName=master)

This config file sets up a headnode that has a managed identity configured, which has contributer access to the resource group.
With the install az-cli, it can create and delete resources without requiring additional authentication/authorization.
To use the az cli, start by log in using "az login -i".
