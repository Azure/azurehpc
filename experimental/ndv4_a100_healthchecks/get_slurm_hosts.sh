#!/bin/bash

SLURM_NODELIST="hpc-pg0-[1-4]"
HOSTFILE=hostlist

sudo scontrol show hostname $SLURM_NODELIST >& $HOSTFILE
