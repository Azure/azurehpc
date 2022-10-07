# Build a ND40rs_v2 GPU cluster with correct GPU mapping

Visualisation: [config.json](https://azurehpc.azureedge.net/?o=https://raw.githubusercontent.com/Azure/azurehpc/master/examples/gpu_numa_mapping/config.json)

The ND40rs_v2 vm has 8 v100 GPU's. This example sets up a GPU cluster and calculates the correct GPU mapping (including correct mapping of GPU's to host NUMA domains). This uses nvidia-smi for the GPU topology and the cuda bandwidthTest benchmark to determine the correct GPU to numa mapping. The correct GPU mapping is deposited on each GPU in /tmp/gpu_map_file. A script (bwtest_gpu_map.sh)  to determine the gpu mapping using only cuda bandwidth test is also include (good sanity test). The script bwtest_gpu_map.sh runs a cuda BW test from each GPU to core 0-1 (Numa domain 0), then sorts the BW results and writes the GPU map to /tmp/gpu_map_file, the BW results are also deposited to /tmp/gpu_bwtest_file.

## Initialise the project

To start you need to copy this directory and update the `config.json`.  Azurehpc provides the `azhpc-init` command that can help here by copying the directory and substituting the unset variables.  First run with the `-s` parameter to see which variables need to be set:

```
azhpc-init -c $azhpc_dir/examples/gpu_numa_mapping -d gpu_numa_mapping -s
```

The variables can be set with the `-v` option where variables are comma separated.  The output from the previous command as a starting point.  The `-d` option is required and will create a new directory name for you.  Please update to whatever `resource_group` you would like to deploy to:

```
azhpc-init -c $azhpc_dir/examples/gpu_numa_mapping -d gpu_numa_mapping -v resource_group=azurehpc-cluster
```

## Create the cluster 

```
cd gpu_numa_mapping
azhpc-build
```

Allow ~10 minutes for deployment.  You are able to view the status VMs being deployed by running `azhpc-status` in another terminal.

## Log in the cluster

Check the GPU numa_mapping file on each ND40rs_v2 instance.

```
cat /tmp/gpu_map_file
3,4,5,6,7,2,1,0
```
