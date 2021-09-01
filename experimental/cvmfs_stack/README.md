# CVMFS on Azure Blob (WIP)

This project contains the scripts to automate the setup of a Stratum 0 server, the creation of a new CVMFS repository on Azure Blob and the configuration of CVMFS clients.

**cvmfs_stratum0_install.sh** - Install all CVMFS Stratum 0 required components.

**cvmfs_repo_init.sh** - Configure and create new CVMFS repository using Azure Blob as storage backend and Azure Keyvault for secrets storage.

**cvmfs_client_setup.sh** - Setup new CVMFS client.
