# Install and run abaqus Benchmarks using azurehpc cluster
These instructions will guide you in building a PBS cluster with Abaqus installed on a share.

## Step 1 - install azhpc

Clone the azhpc repository and source the `install.sh` script.

```
$ git clone https://github.com/Azure/azurehpc.git
$ cd azurehpc
$ . install.sh
$ cd ..
```

## Step 2 - Initialize the configuration files
Create a working directory from where you will do the deployment and configuration update. Don't work directly from the cloned repo.

```
$ mkdir abaqus
$ cd abaqus
```

Then copy the `init.sh` and `variables.json` from `apps/abaqus` to your working directory.

```
$ cp $azhpc_dir/apps/abaqus/init.sh .
$ cp $azhpc_dir/apps/abaqus/variables.json .
```

Edit the `variables.json` to match your environment. The storage variables are those containing the **Abaqus** tar installation files :
- 2020.AM_SIM_Abaqus_Extend.AllOS.1-4.tar
- 2020.AM_SIM_Abaqus_Extend.AllOS.2-4.tar
- 2020.AM_SIM_Abaqus_Extend.AllOS.3-4.tar
- 2020.AM_SIM_Abaqus_Extend.AllOS.4-4.tar


```json
{
  "variables": {
    "resource_group": "my resource group",
    "location": "my location",
    "vm_type": "Standard_HB60rs",
    "license_server": "x.x.x.x",
    "app_storage_account": "<NOT-SET>",
    "app_container": "<NOT-SET>",
    "app_folder": "abaqus-2020"
  }
}
```

Run the `init.sh` script which will copy all the config files of the building blocks and initialize the variables by using the `variables.json` updated above.

```
$ ./init.sh
```

## Step 3 - Build the system

Check that the `abaqus.json` file contains the right settings, eventually edit it and add more instances.

```
$ azhpc-build -c abaqus.json
```

The build process should take about 13-15 minutes.

## Step 4 - Copy input data and run scripts

Next, copy the <model>.inp file to the headnode under `/data`

```
azhpc-scp -c abaqus.json <model>.inp hpcadmin@headnode:/data/.
azhpc-scp -c abaqus.json $azhpc_dir/apps/abaqus/abaqus_impi.sh hpcadmin@headnode:/apps/.
```

## Step 5 - Run jobs
Connect to the headnode

```
azhpc-connect -c abaqus.json headnode
qsub -l select=2:ncpus=60:mpiprocs=60,place=scatter:excl -- /apps/abaqus_impi.sh
```

Note: You can pass variables to the script by using -v for e.g. -v "MODEL=<model name>" 

