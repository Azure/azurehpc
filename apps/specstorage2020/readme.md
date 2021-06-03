TEST





Prerequisites
Cluster is built with the desired configuration for networking, storage, compute etc. The simple_hpc_pbs template in the examples directory is a suitable choice.

After cluster is built, first copy the apps directory to the cluster. The azhpc-scp can be used to do this:

azhpc-scp -u hpcuser -r $azhpc_dir/apps hpcuser@headnode:.
Then connect to the headnode:

azhpc-connect -u hpcuser headnode
Or simply create a Azure Virtual machine with CentOS and ssh connect to it.

Install BLAST, download BlastDB, input file, query string
Take a look at the 'install_blast.sh' script, modify the installation directory if needed:

vim install_blast.sh
Run the 'install_blast.sh' script:

source install_blast.sh
Run BLAST
Change folder to your BLAST installation directory

source test.sh
