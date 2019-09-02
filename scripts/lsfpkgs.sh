#!/bin/bash
lsf_product_sas="$1"
lsf_product_sp7_sas="$2"
lsf_install_sas="$3"
lsf_entitlement_sas="$4"

LSF_DOWNLOAD_DIR=/apps/lsf

mkdir -p $LSF_DOWNLOAD_DIR
cd $LSF_DOWNLOAD_DIR

filename=$(echo ${lsf_product_sas##*/} | cut -d'?' -f1)
wget "$lsf_product_sas" -O ${filename}
gunzip $filename
tar -xf ${filename%.*}

filename=$(echo ${lsf_product_sp7_sas##*/} | cut -d'?' -f1)
wget "$lsf_product_sp7_sas" -O ${filename}
gunzip $filename
tar -xf ${filename%.*}

filename=$(echo ${lsf_install_sas##*/} | cut -d'?' -f1)
wget "$lsf_install_sas" -O ${filename}
gunzip $filename
tar -xf ${filename%.*}

filename=$(echo ${lsf_entitlement_sas##*/} | cut -d'?' -f1)
wget "$lsf_entitlement_sas" -O ${filename}

