# How to run the Fairseq (MOE version) Deep learning training benchmark using enroot+pyxis or Docker with SLURM

Details of the Meta fairseq (MOE version) deep leaning Natural language processing model can be found [here](https://github.com/pytorch/fairseq/blob/moe/README.moe.md).
Mixture of experts (MOE) is a model parallel technique that enables extremely large deep learning models (> 1T parameters)
possible on todays latest GPU's.

Size of Deep learning training model
```
Total number of paramters = Number of GPUS * 2B + 4.5B
```

This workflow can be deployed in one of three ways. The first approach is enroot+pyxis with SLURM. The second approach is Docker with SLURM. The last option is [Azure Machine Learning](https://learn.microsoft.com/en-us/azure/machine-learning/). The details are described below.

## Enroot + Pyxis with SLURM

### Prerequisites

- SLURM scheduler
- Compute node(s), ND96asr_v4 (Running Ubuntu-hpc 18.04)
- Enroot and pyxis deployed

### Authenticate with NVIDIA API Key
```bash
mkdir -p $HOME/.config/enroot/
echo "machine nvcr.io login $oauthtoken password YOUR_KEY" > $HOME/.config/enroot/.credentials
```
>Note: NVIDIA API key can be configured in the [NVIDIA NGC webpage](https://ngc.nvidia.com/setup/api-key). 

### Import base image and install dependencies
```bash
enroot import docker://nvcr.io/nvidia/pytorch:21.10-py3
enroot create --name pytorch nvidia+pytorch+21.10-py3.sqsh
enroot list
enroot start --root --rw --mount .:/workspace pytorch
bash image.config
```

### Save the squashfs image
```bash
enroot export --output fairseq.sqsh pytorch
enroot create --name fairseq fairseq.sqsh
enroot list
```

### Submit the SLURM using run_fairseq_moe_enroot_pyxis.slrm
```
sbatch -N 1 run_fairseq_moe_enroot_pyxis.slrm
```
>Note: The job can be deployed on multiple nodes by changing the -N parameter. The number of nodes available depends on the CycleCloud cluster setup. 

## Docker with SLURM

### Prerequisites

- SLURM scheduler
- Compute node(s), ND96asr_v4 (Running Ubuntu-hpc 18.04)
- Azure container registry deployed

### Docker set-up on compute nodes and scheduler

```
pdsh -w ^/path/to/hostfile sudo </path/to/docker_setup.sh
```
>Note: Make sure scheduler and the compute nodes have the name GID for the docker group. Modify script update "USER".


### Build docker container

```
az acr build --registry <your_acr_name> --image docker/<container_name:version> .
```
>Note: Make sure you are in the same directory as yur Dockerfile. Change "your_acr_name", "container_name" and 
"version" to appropriate values for your ACR, the name/version of your container respectively.


### Run fairseq_moe benchmark

```
sbatch -N <Number of nodes> run_fairseq_moe_docker.slrm
```
>Note: Modify run_fairseq_moe_docker.slrm, updating appropriate vlaues for "DOCKER_USERNAME", "DOCKER_PASSWD", "CONTAINER_NAME" and "EXECUTE_SCRIPT". If you are using a shared filesystem, you will only need to authenicate to docker once and can remove docker login from the run_fairseq_moe_docker.slrm script. If you would like to do a restart of a job then comment out "rm $SAVE_DIR/*"


### Verify benchmark Ran ok

Check the end of the SLURM output file.

```
2022-04-24 00:13:42 | INFO | fairseq_cli.train | Stopping training due to num_updates: 30 >= max_update: 30
2022-04-24 00:13:42 | INFO | fairseq.checkpoint_utils | Preparing to save checkpoint for epoch 1 @ 30 updates
2022-04-24 00:13:50 | INFO | fairseq.trainer | Saving checkpoint to /workspace/mnt/resource_nvme/checkpoints/checkpoint_last-rank-0
-shard0.pt
2022-04-24 00:13:59 | INFO | fairseq.trainer | Finished saving checkpoint to /workspace/mnt/resource_nvme/checkpoints/checkpoint_la
st-rank-0-shard0.pt
2022-04-24 00:13:59 | INFO | fairseq.trainer | Saving checkpoint to /workspace/mnt/resource_nvme/checkpoints/checkpoint_last-shared
-shard0.pt
2022-04-24 00:14:08 | INFO | fairseq.trainer | Finished saving checkpoint to /workspace/mnt/resource_nvme/checkpoints/checkpoint_la
st-shared-shard0.pt
2022-04-24 00:14:08 | INFO | fairseq.checkpoint_utils | Saved checkpoint /workspace/mnt/resource_nvme/checkpoints/checkpoint_last-r
ank-0-shard0.pt (epoch 1 @ 30 updates, score None) (writing took 26.03772440999819 seconds)
2022-04-24 00:14:08 | INFO | fairseq_cli.train | end of epoch 1 (average epoch stats below)
2022-04-24 00:14:08 | INFO | train | {"epoch": 1, "train_loss": "16.193", "train_moe_gate_loss": "18.9082", "train_overflow_expert1
": "11.062", "train_overflow_expert2": "48.916", "train_entropy_gating": "2.013", "train_expert1_balance_top": "55.954", "train_exp
ert1_balance_bottom": "4.778", "train_unused_expert1_count": "0.456", "train_expert2_balance_top": "43.854", "train_expert2_balance
_bottom": "7.277", "train_unused_expert2_count": "0.318", "train_all_to_all_cpu_time_ms": "0", "train_all_to_all_cuda_time_ms": "0"
, "train_inner_loss": "15.92", "train_ppl": "62007.4", "train_wps": "25512.9", "train_ups": "0.13", "train_wpb": "196608", "train_b
sz": "192", "train_num_updates": "30", "train_lr": "2.06667e-05", "train_gnorm": "10.765", "train_loss_scale": "8", "train_train_wa
ll": "547", "train_cuda_gb_allocated": "16.5", "train_cuda_gb_reserved": "30", "train_cuda_gb_free": "23.1", "train_wall": "575"}
2022-04-24 00:14:08 | INFO | fairseq_cli.train | done training in 573.6 seconds
6698,1Bot
```

### To adjust the runtime of benchmark

In the launch.sh script increase or decrease the parameter MAX_UPDATE

## Azure Machine Learning

### Setup local environment for Azure Machine Learning  
Install Azure Machine Learning Python SDK v1
```bash
pip install azureml-core
```
Install `ml` extension
```bash
az extension add -n ml
```

### Create AML workspace  
[Reference](https://learn.microsoft.com/en-us/azure/machine-learning/how-to-configure-cli?tabs=public)
```bash
az login
az account set --name YOUR_SUBSCRIPTION_NAME

GROUP="YOUR_RESOURCE_GROUP"
LOCATION="YOUR_RESOURCE_REGION"
WORKSPACE="YOUR_WORKSPACE_NAME"

# Create the resource group if it doesn't alreayd exist. 
az group create -n $GROUP -l $LOCATION

# Create AML workspace
az ml workspace create -n $WORKSPACE -g $GROUP -l $LOCATION
```
>Note: Azure resource group and AML workspace will be created by above commands if they don't exist alreay. 

### Build the docker environment  
[Reference](https://learn.microsoft.com/en-us/azure/machine-learning/concept-environments)
```bash
cd environment
az ml environment create --file pytorch_env.yml
```
>Note: This step will create a docker image in Azure Container Registry. 

### Submit the job to AML
```bash
python run_fairseq_moe_aml.py
```
>Note: Replace the user-defined variables in `run_fairseq_moe_aml.py` before you submit it to the AML workspace. 

### Sample output from AML experiment
```bash
2022-10-18 04:40:58 | INFO | fairseq_cli.train | Stopping training due to num_updates: 25 >= max_update: 25
2022-10-18 04:40:58 | INFO | fairseq.checkpoint_utils | Preparing to save checkpoint for epoch 1 @ 25 updates
2022-10-18 04:41:08 | INFO | fairseq.trainer | Saving checkpoint to ./checkpoint_last-rank-0-shard0.pt
2022-10-18 04:41:26 | INFO | fairseq.trainer | Finished saving checkpoint to ./checkpoint_last-rank-0-shard0.pt
2022-10-18 04:41:26 | INFO | fairseq.trainer | Saving checkpoint to ./checkpoint_last-shared-shard0.pt
2022-10-18 04:41:48 | INFO | fairseq.trainer | Finished saving checkpoint to ./checkpoint_last-shared-shard0.pt
2022-10-18 04:41:48 | INFO | fairseq.checkpoint_utils | Saved checkpoint ./checkpoint_last-rank-0-shard0.pt (epoch 1 @ 25 updates, score None) (writing took 49.164279436998186 seconds)
2022-10-18 04:41:48 | INFO | fairseq_cli.train | end of epoch 1 (average epoch stats below)
2022-10-18 04:41:48 | INFO | train | {"epoch": 1, "train_loss": "17.131", "train_moe_gate_loss": "19.2701", "train_overflow_expert1": "12.021", "train_overflow_expert2": "50.689", "train_entropy_gating": "2.006", "train_expert1_balance_top": "57.114", "train_expert1_balance_bottom": "4.243", "train_unused_expert1_count": "0.522", "train_expert2_balance_top": "44.746", "train_expert2_balance_bottom": "6.444", "train_unused_expert2_count": "0.357", "train_all_to_all_cpu_time_ms": "0", "train_all_to_all_cuda_time_ms": "0", "train_inner_loss": "16.853", "train_ppl": "118351", "train_wps": "22296.5", "train_ups": "0.11", "train_wpb": "196608", "train_bsz": "192", "train_num_updates": "25", "train_lr": "1.73333e-05", "train_gnorm": "12.484", "train_loss_scale": "8", "train_train_wall": "510", "train_cuda_gb_allocated": "16.5", "train_cuda_gb_reserved": "30.1", "train_cuda_gb_free": "62.9", "train_wall": "561"}
2022-10-18 04:41:48 | INFO | fairseq_cli.train | done training in 559.6 seconds
```

