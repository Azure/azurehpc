#!/bin/bash

CLUSTERKIT_RESULTS_DIR_PATH=$1

sudo yum install -y python-pip
sudo pip install python-hostlist

module load mpi/hpcx

cd $CLUSTERKIT_RESULTS_DIR_PATH
python `which bwResultAnalyzer.py` -f bandwidth.json
