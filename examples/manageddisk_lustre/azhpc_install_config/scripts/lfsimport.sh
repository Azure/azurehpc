#!/bin/bash

# arg: $1 = storage account
# arg: $2 = storage key
# arg: $3 = storage container
storage_account=$1
storage_key=$2
storage_container=$3

yum install -y \
    https://github.com/whamcloud/lemur/releases/download/0.5.2/lhsm-0.5.2-1.x86_64.rpm

wget https://dl.google.com/go/go1.12.1.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.12.1.linux-amd64.tar.gz
export PATH=/usr/local/go/bin:$PATH

yum install -y git gcc
go get -u github.com/edwardsp/lemur/cmd/azure-import
go build github.com/edwardsp/lemur/cmd/azure-import
mkdir -p /usr/local/bin
cp azure-import /usr/local/bin/.

cd /lustre
export STORAGE_ACCOUNT=$storage_account
export STORAGE_KEY=$storage_key
/usr/local/bin/azure-import ${storage_container}

