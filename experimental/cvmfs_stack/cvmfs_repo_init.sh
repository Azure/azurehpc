#!/bin/bash
set -euo pipefail

# # # # # # # # # # # # # # # # # # # #
RESOURCE_GROUP_NAME=dv-buildstack
STORAGE_ACCOUNT_NAME=dvcvmfs
CONTAINER_NAME=repo06
KEYVAULT_NAME=cvmfskv
MASTERKEY_SECRET_NAME=CvmfsAzureMasterkey
CVMFS_USER=hpcadmin
SIGNATURE_EXPIRATION_DAYS=360
# # # # # # # # # # # # # # # # # # # #

# Check that Azure CLI is installed
if ! command -v az &> /dev/null; then
  printf "\nERROR: Azure CLI not found. Please install it and try again.\n\n"
  exit
fi

# Check that Azure CLI is logged in
if ! az keyvault key list --vault-name ${KEYVAULT_NAME} &> /dev/null; then
  printf "\nERROR: Azure CLI is not logged in. Please log in and try again.\n\n"
  exit
fi

# Check if azcopy is available, otherwise download it
if ! command -v azcopy &> /dev/null; then
  wget https://azcopyvnext.azureedge.net/release20210415/azcopy_linux_amd64_10.10.0.tar.gz
  tar xzf azcopy_linux_amd64_10.10.0.tar.gz
  rm -f azcopy_linux_amd64_10.10.0.tar.gz
  rm -rf azcopy_tmp
  mv azcopy_linux_amd64_10.10.0 azcopy_tmp
  export PATH=${PWD}/azcopy_tmp:$PATH
fi

# Create Azure Blob container
az storage container create --account-name ${STORAGE_ACCOUNT_NAME} --name ${CONTAINER_NAME} --public-access container

# Configure repository
BLOB_KEY=$(az storage account keys list -g ${RESOURCE_GROUP_NAME} -n ${STORAGE_ACCOUNT_NAME} --query "[?keyName=='key2'].value" -o tsv)
sudo tee /etc/cvmfs/${CONTAINER_NAME}.azure.conf > /dev/null << EOF
CVMFS_S3_HOST=${STORAGE_ACCOUNT_NAME}.blob.core.windows.net
CVMFS_S3_ACCESS_KEY=${STORAGE_ACCOUNT_NAME}
CVMFS_S3_SECRET_KEY=${BLOB_KEY}
CVMFS_S3_BUCKET=${CONTAINER_NAME}
CVMFS_S3_DNS_BUCKETS=false
CVMFS_S3_FLAVOR=azure
EOF

sudo cvmfs_server mkfs -s /etc/cvmfs/${CONTAINER_NAME}.azure.conf -w http://${STORAGE_ACCOUNT_NAME}.blob.core.windows.net/${CONTAINER_NAME} -o ${CVMFS_USER}  ${CONTAINER_NAME}.azure

# Check if secret containing master key already exists in key vault
if az keyvault secret list --vault-name ${KEYVAULT_NAME} | grep ${MASTERKEY_SECRET_NAME} > /dev/null; then 
  # Download common masterkey from key vault
  az keyvault secret download --file ${STORAGE_ACCOUNT_NAME}.azure.masterkey --name ${MASTERKEY_SECRET_NAME} --vault-name ${KEYVAULT_NAME}
  sudo mv ${STORAGE_ACCOUNT_NAME}.azure.masterkey /etc/cvmfs/keys
  sudo chown root:root /etc/cvmfs/keys/${STORAGE_ACCOUNT_NAME}.azure.masterkey
else
  # Rename masterkey
  sudo mv /etc/cvmfs/keys/${CONTAINER_NAME}.azure.masterkey /etc/cvmfs/keys/${STORAGE_ACCOUNT_NAME}.azure.masterkey
  # Upload repository masterkey to key vault secret
  az keyvault secret set -n ${MASTERKEY_SECRET_NAME} --vault-name ${KEYVAULT_NAME} --value "$(cat /etc/cvmfs/keys/${STORAGE_ACCOUNT_NAME}.azure.masterkey)"
fi

# Replace automatically generated masterkey with common masterkey
sudo rm -f /etc/cvmfs/keys/${CONTAINER_NAME}.azure.masterkey
sudo ln -s /etc/cvmfs/keys/${STORAGE_ACCOUNT_NAME}.azure.masterkey /etc/cvmfs/keys/${CONTAINER_NAME}.azure.masterkey

# Replace the public key with a newly generated common public key
sudo rm -f /etc/cvmfs/keys/${CONTAINER_NAME}.azure.pub
openssl rsa -in /etc/cvmfs/keys/${STORAGE_ACCOUNT_NAME}.azure.masterkey -pubout | sudo tee /etc/cvmfs/keys/${STORAGE_ACCOUNT_NAME}.azure.pub &> /dev/null
sudo ln -s /etc/cvmfs/keys/${STORAGE_ACCOUNT_NAME}.azure.pub /etc/cvmfs/keys/${CONTAINER_NAME}.azure.pub

# Resign the repository whitelist
sudo cvmfs_server resign -d ${SIGNATURE_EXPIRATION_DAYS} ${CONTAINER_NAME}.azure

# Upload certificate and key to key vault secrets
az keyvault secret set -n ${CONTAINER_NAME}AzureCrt --vault-name ${KEYVAULT_NAME} --value "$(cat /etc/cvmfs/keys/${CONTAINER_NAME}.azure.crt)"
az keyvault secret set -n ${CONTAINER_NAME}AzureKey --vault-name ${KEYVAULT_NAME} --value "$(cat /etc/cvmfs/keys/${CONTAINER_NAME}.azure.key)"

# Add CVMFS repository public key and client configuration to blob
EXP=$(date --date='1 day' +%Y-%m-%d)
SAS_KEY=$(az storage container generate-sas --account-name ${STORAGE_ACCOUNT_NAME} --name ${CONTAINER_NAME} --permissions rw --expiry ${EXP} -o tsv)
azcopy copy /etc/cvmfs/keys/${STORAGE_ACCOUNT_NAME}.azure.pub "https://${STORAGE_ACCOUNT_NAME}.blob.core.windows.net/${CONTAINER_NAME}?${SAS_KEY}"

cat << EOF > ${CONTAINER_NAME}.azure.conf
CVMFS_SERVER_URL=http://${STORAGE_ACCOUNT_NAME}.blob.core.windows.net/${CONTAINER_NAME}/${CONTAINER_NAME}.azure
CVMFS_PUBLIC_KEY=/etc/cvmfs/keys/${STORAGE_ACCOUNT_NAME}.azure.pub
CVMFS_HTTP_PROXY=DIRECT
EOF
azcopy copy ${CONTAINER_NAME}.azure.conf "https://${STORAGE_ACCOUNT_NAME}.blob.core.windows.net/${CONTAINER_NAME}?${SAS_KEY}"
rm -f ${CONTAINER_NAME}.azure.conf

# Delete temporary azcopy directory
rm -rf azcopy_tmp

# Allow automatic catalog management
sudo sed -i 's/CVMFS_AUTOCATALOGS=false/CVMFS_AUTOCATALOGS=true/g' /etc/cvmfs/repositories.d/${CONTAINER_NAME}.azure/server.conf
