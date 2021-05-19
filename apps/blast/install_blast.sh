#!/bin/bash
WORKING_DIR=/mnt/resource
INSTALL_DIR=/mnt/resource

# prerequistics and system update
cd
yum -y update
wget https://aka.ms/downloadazcopy-v10-linux
tar zxf downloadazcopy-v10-linux

# install blast
wget https://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/ncbi-blast-2.11.0+-1.x86_64.rpm
rpm -ivh ncbi-blast-2.11.0+-1.x86_64.rpm  --nodeps --force

# get testing blast db (~1.2TB)
mkdir $INSTALL_DIR
cd $INSTALL_DIR

~/azcopy_linux_amd64_10.10.0/azcopy copy "https://raymondstorage.blob.core.windows.net/blast?sv=2020-04-08&st=2021-05-17T06%3A40%3A51Z&se=2023-05-18T06%3A40%3A00Z&sr=c&sp=rl&sig=tRAjIWPNq9WktdGeYrenoczm8vs9DS4MSJhRbS9agro%3D" . --recursive=true
