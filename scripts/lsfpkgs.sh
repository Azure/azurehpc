#!/bin/bash
lsf_product_sas="$1"
lsf_product_sp7_sas="$2"
lsf_install_sas="$3"
lsf_entitlement_sas="$4"

LSF_DOWNLOAD_DIR=/mnt/resource

pushd $LSF_DOWNLOAD_DIR

# Get product file
filename=$(echo ${lsf_product_sas##*/} | cut -d'?' -f1)
wget -q "$lsf_product_sas" -O ${filename}

# Get patch file
filename=$(echo ${lsf_product_sp7_sas##*/} | cut -d'?' -f1)
wget -q "$lsf_product_sp7_sas" -O ${filename}

# Get entitlement file
filename=$(echo ${lsf_entitlement_sas##*/} | cut -d'?' -f1)
wget -q "$lsf_entitlement_sas" -O ${filename}

# Get and untar installer
filename=$(echo ${lsf_install_sas##*/} | cut -d'?' -f1)
wget -q "$lsf_install_sas" -O ${filename}
gunzip $filename
tar -xf ${filename%.*}

