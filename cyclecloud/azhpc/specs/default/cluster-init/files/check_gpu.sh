#!/bin/bash

gpu_cards=$(/usr/sbin/lspci | grep -i NVIDIA | wc -l)
echo "$gpu_cards NVIDIA devices found"
if [ $gpu_cards -eq 0 ]; then
    echo "ERROR : no NVIDIA devices found"
    exit 1
fi

nvidia-smi || exit 1
