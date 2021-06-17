#!/bin/bash

username=$1
password=$2

sudo yum -y install python3
sudo yum -y install pip3
sudo pip3 install PyYAML
# required on CentOS 8.+
sudo pip install -U PyYAML

wget --user $username --password $password https://pro.spec.org/private/osg/benchmarks/sfs/SPECstorage_2020.iso
mkdir SFS
sudo mount -o loop SPECstorage_2020.iso SFS/

cd SFS/SPECstorage2020/

sudo python3 SM2020 --install-dir="../../SPECstorage_2020"

cd

sudo chown $USER:$USER SPECstorage_2020/ -R
sudo chmod 777 SPECstorage_2020/ -R
