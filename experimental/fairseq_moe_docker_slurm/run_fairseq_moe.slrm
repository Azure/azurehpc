#!/bin/sh

#SBATCH --job-name=fairseq_moe
#SBATCH --output=./stdout.%j
#SBATCH --error=./stderr.%j
#SBATCH --ntasks-per-node=1
#SBATCH --mem=0
#SBATCH --gpus-per-node=8
#SBATCH --cpus-per-task=96

DOCKER_USERNAME="<DOCKER_USERNAME>"
DOCKER_PASSWD="<DOCKER_PASSWORD>"

CONTAINER_NAME="<CONTAINER_NAME>"
DOCKER_ARGS="--gpus all --rm"
CONTAINER_ENV="--env SLURM_NODEID --env SLURM_NNODES --env SLURM_SUBMIT_HOST"
CONTAINER_MOUNTS="-v $HOME:$HOME -v /opt:/workspace/opt:ro -v /mnt:/workspace/mnt"
CONTAINER_LIMITS="--shm-size=256m --ulimit memlock=-1"
CONTAINER_DEVICES="--privileged --ipc=host --net=host"

EXECUTE_SCRIPT="<PATH_TO>/launch.sh"

CONTAINER="$DOCKER_USERNAME.azurecr.io/docker/$CONTAINER_NAME"


srun docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWD ${DOCKER_USERNAME}.azurecr.io

srun docker run $DOCKER_ARGS $CONTAINER_ENV $CONTAINER_MOUNTS $CONTAINER_LIMITS $CONTAINER_DEVICES $CONTAINER $EXECUTE_SCRIPT
