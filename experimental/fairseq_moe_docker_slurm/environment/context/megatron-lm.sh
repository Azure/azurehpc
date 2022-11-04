#!/bin/bash

git clone --depth=1 --branch v2.6 https://github.com/NVIDIA/Megatron-LM.git
cd Megatron-LM
pip install -e .
