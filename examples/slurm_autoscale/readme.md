# Create an autoscaling slurm cluster
![Build Status](https://azurecat.visualstudio.com/hpccat/_apis/build/status/azhpc/examples/slurm_autoscale?branchName=master)

Visualisation: [config.json](https://azurehpc.azureedge.net/?o=https://raw.githubusercontent.com/Azure/azurehpc/master/examples/slurm_autoscale/config.json)

This will create an autoscaling cluster using the SLURM scheduler.  The headnode is set up with a managed identity and azurehpc is used to scale nodes up and down.  The new resource type `slurm_partition` is the template for the VM being created.