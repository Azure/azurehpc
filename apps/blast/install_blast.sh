#!/bin/bash
SAS_URL=$1
WORKING_DIR=/mnt/resource
INSTALL_DIR=/mnt/resource

# system update
cd
yum -y update

# install blast
wget https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/ncbi-blast-2.11.0+-1.x86_64.rpm
rpm -ivh ncbi-blast-2.11.0+-1.x86_64.rpm  --nodeps --force

# get testing blast db (~1.2TB)
mkdir $INSTALL_DIR
cd $INSTALL_DIR

~/azcopy_linux_amd64_10.10.0/azcopy copy "$SAS_URL" . --recursive=true
