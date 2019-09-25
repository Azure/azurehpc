#!/bin/bash

yum-config-manager --add-repo https://yum.repos.intel.com/setup/intelproducts.repo
rpm --import https://yum.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2019.PUB
yum install -y intel-mpi-2018.4-057
