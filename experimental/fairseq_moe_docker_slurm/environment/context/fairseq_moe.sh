#!/bin/bash

git clone https://github.com/pytorch/fairseq
cd fairseq
git checkout moe
python setup.py build_ext --inplace
