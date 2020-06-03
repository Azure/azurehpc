# Performance Testing: Samba exporting BeeGFS

Prerequisite:
* Azure CLI should be installed and you should be logged in

To run clone the azurehpc repo:

    git clone https://github.com/Azure/azurehpc.git

Source the install script to set up the environment:

    source azurehpc/install.sh

Move to this directory and launch the tests:

    cd azurehpc/experimental/beegfs_samba
    ./param_sweep.sh

This will run four tests:

* 2 BeeGFS storage nodes using F48s_v2 and up to 16 D32_v3 clients with accelerated networking
* 2 BeeGFS storage nodes using F48s_v2 and up to 16 D32_v3 clients without accelerated networking
* 8 BeeGFS storage nodes using D48s_v2 and up to 16 D32_v3 clients with accelerated networking
* 8 BeeGFS storage nodes using D48s_v2 and up to 16 D32_v3 clients without accelerated networking

To summarize the data run:

    ./process.sh azhpc_install_*

