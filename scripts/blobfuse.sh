#!/bin/bash

blob_account=$1
blob_container=$2
blob_key=$3
blob_mount=$4

sudo rpm -Uvh https://packages.microsoft.com/config/rhel/7/packages-microsoft-prod.rpm
sudo yum install -y blobfuse fuse

export AZURE_STORAGE_ACCOUNT=${blob_account}
export AZURE_STORAGE_ACCESS_KEY="${blob_key}"

sudo mkdir -p /mnt/resource/blobfusetmp
sudo chmod 777 /mnt/resource/blobfusetmp
sudo mkdir -p /${blob_mount}
sudo chmod 777 /${blob_mount}

blobfuse /${blob_mount} --container-name=${blob_container} --tmp-path=/mnt/resource/blobfusetmp

