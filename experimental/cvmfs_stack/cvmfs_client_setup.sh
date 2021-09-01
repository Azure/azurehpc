#!/bin/bash
set -eou pipefail

CVMFS_BLOB_URL='<blob_url>'

sudo yum install -y epel-release
sudo yum install -y jq

# Install CVMFS client component
if ! rpm -qa | grep 'cvmfs-release'; then
   sudo yum install -y https://ecsft.cern.ch/dist/cvmfs/cvmfs-release/cvmfs-release-latest.noarch.rpm
fi
sudo yum install -y cvmfs

# Get lowercase VM SKU without "Standard_"
VMSKU=$(curl -s --noproxy "*" -H Metadata:true "http://169.254.169.254/metadata/instance/compute?api-version=2019-08-15" | \
        jq -r '.vmSize' | tr '[:upper:]' '[:lower:]' | sed -e 's/[^_]*_//')

# Get OS name and version
OS_NAME=$(curl -s -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance?api-version=2020-09-01" | \
          jq -r '.compute.storageProfile.imageReference.offer')
OS_VERSION=$(curl -s -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance?api-version=2020-09-01" | \
             jq -r '.compute.storageProfile.imageReference.version')

case $VMSKU in
  hb120rs_v2)
    CONTAINER_URL=${CVMFS_BLOB_URL}/hbv2
    REPO_NAME="hbv2.azure"
    ;;
  *)
    CONTAINER_URL=${CVMFS_BLOB_URL}/generic
    REPO_NAME="generic.azure"
    ;;
esac

CVMFS_ROOT="/cvmfs/${REPO_NAME}"
STACK_ROOT="${CVMFS_ROOT}/${OS_NAME}/${OS_VERSION}"

sudo curl ${CONTAINER_URL}/${REPO_NAME}.conf -o /etc/cvmfs/config.d/${REPO_NAME}.conf
sudo curl ${CONTAINER_URL}/cvmfs.azure.pub -o /etc/cvmfs/keys/cvmfs.azure.pub
sudo cvmfs_config setup

sudo systemctl disable autofs
sudo systemctl stop autofs

sudo mkdir -p ${CVMFS_ROOT}

if ! grep "$CVMFS_ROOT" /etc/fstab; then
  echo "${REPO_NAME} ${CVMFS_ROOT} cvmfs defaults,_netdev,nodev 0 0" | sudo tee -a /etc/fstab
fi

if ! findmnt ${CVMFS_ROOT}; then
  sudo mount -a
fi
