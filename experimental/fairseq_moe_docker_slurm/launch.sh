#!/bin/bash
  
export NCCL_DEBUG=INFO
export UCX_TLS=tcp
export UCX_NET_DEVICES=eth0
export NCCL_SOCKET_IFNAME=eth0
export CUDA_DEVICE_ORDER=PCI_BUS_ID
export NCCL_IB_PCI_RELAXED_ORDERING=1
export NCCL_TOPO_FILE=/workspace/opt/microsoft/ndv4-topo.xml

MASTER_PORT=18171
MASTER_ADDR=$SLURM_SUBMIT_HOST
SAVE_DIR=/workspace/mnt/resource_nvme/checkpoints
NUM_GPUS_PER_NODE=8
NUM_EXPERTS=8
TOKENS_PER_SAMPLE=1024
BATCH_SIZE=6
MAX_UPDATE=250
GRAD_ACC=2

mkdir -p $SAVE_DIR
rm $SAVE_DIR/*

cd fairseq
python -m torch.distributed.launch --nproc_per_node=${NUM_GPUS_PER_NODE}  --nnodes=$SLURM_NNODES --node_rank=$SLURM_NODEID \
--master_addr=$MASTER_ADDR --master_port=$MASTER_PORT \
train.py \
--save-dir $SAVE_DIR \
--ddp-backend fully_sharded --memory-efficient-fp16 --checkpoint-activations \
--task dummy_lm --tokens-per-sample $TOKENS_PER_SAMPLE \
--arch transformer_lm_gpt --share-decoder-input-output-embed \
--decoder-layers 32 --decoder-embed-dim 4096 --decoder-ffn-embed-dim 16384 \
--decoder-attention-heads 32 \
--moe-expert-count $NUM_EXPERTS --moe-freq 2 \
--moe-gating-use-fp32 --moe-second-expert-policy all \
--moe-normalize-expert-grad sqrt_world_size \
--moe-eval-capacity-token-fraction -1.0 \
--max-sentences-valid 1 --num-workers-valid 0 \
--criterion moe_cross_entropy --moe-gate-loss-wt 0.01 --moe-gate-loss-combine-method sum \
--optimizer adam --fp16-adam-stats --adam-betas '(0.9,0.98)' --clip-norm 0.0 \
--lr 0.0005 --warmup-updates 750 \
--dropout 0.1 --attention-dropout 0.1 \
--batch-size $BATCH_SIZE --update-freq $GRAD_ACC \
--max-update $MAX_UPDATE --disable-validation \
--log-format json --log-interval 10
