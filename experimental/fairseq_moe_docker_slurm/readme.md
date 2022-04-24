# How to run the Fairseq (MOE version) Deep learning training benchmark using docker and SLURM

Details of the Meta fariseq (MOE version) deep leaning Natural language processing model can be found [here](https://github.com/pytorch/fairseq/blob/moe/README.moe.md).
Mixture of experts (MOE) is a model parallel technique that enables extremely large deep learning models (> 1T parameters)
possible on todays latest GPU's.

Size of Deep learning training model
```
Total number of paramters = Number of GPUS * 2B + 4.5B
```

## Prerequisites

- SLURM scheduler
- Compute node(s), ND96asr_v4 (Running Ubuntu-hpc 18.04)
- Azure container registry deployed

## Docker set-up on compute nodes and scheduler

```
pdsh -w ^/path/to/hostfile sudo </path/to/docker_setup.sh
```
>Note: Make sure scheduler and the compute nodes have the name GID for the docker group. Modify script update "USER".


## Build docker container

```
az acr build --registry <your_acr_name> --image docker/<container_name:version> .
```
>Note: Make sure you are in the same directory as yur Dockerfile. Change "your_acr_name", "container_name" and 
"version" to appropriate values for your ACR, the name/version of your container respectively.


## Run fairseq_moe benchmark

```
sbatch -N <Number of nodes> run_fairseq_moe.slrm
```
>Note: Modify run_fairseq_moe.slrm, updating appropriate vlaues for "DOCKER_USERNAME", "DOCKER_PASSWD", "CONTAINER_NAME" and "EXECUTE_SCRIPT". If you are using a shared filesystem, you will only need to authenicate to docker once and can remove docker login from the run_fairseq_moe.slrm script. If you would like to do a restart of a job then comment out "rm $SAVE_DIR/*"


## Verify benchmark Ran ok

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

## To adjust the runtime of benchmark

In the launch.sh script increase or decrease the parameter MAX_UPDATE

