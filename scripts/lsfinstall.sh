#!/bin/bash
LSF_DOWNLOAD_DIR=/mnt/resource
LSF_INSTALL_DIR=$LSF_DOWNLOAD_DIR/lsf10.1_lsfinstall
LSF_INSTALL_CONFIG=$LSF_INSTALL_DIR/lsf.install.config

# Fill up install configuration file
cp $LSF_INSTALL_DIR/install.config $LSF_INSTALL_CONFIG
