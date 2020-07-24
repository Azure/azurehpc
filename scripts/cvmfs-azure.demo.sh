#!/bin/bash

yum install -y https://ecsft.cern.ch/dist/cvmfs/cvmfs-release/cvmfs-release-latest.noarch.rpm
yum install -y cvmfs Lmod
cvmfs_config setup
curl https://cvmfs.blob.core.windows.net/demo/public_keys/demo.azure.pub -o /etc/cvmfs/keys/demo.azure.pub
curl https://cvmfs.blob.core.windows.net/demo/public_keys/demo.azure.conf -o /etc/cvmfs/config.d/demo.azure.conf

