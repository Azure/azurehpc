## NCBI BLAST

The Basic Local Alignment Search Tool (BLAST) finds regions of local similarity between sequences. The program compares nucleotide or protein sequences to sequence databases and calculates the statistical significance of matches. BLAST can be used to infer functional and evolutionary relationships between sequences as well as help identify members of gene families.

[NCBI BLAST Home Page](https://blast.ncbi.nlm.nih.gov/Blast.cgi)

## Prerequisites

Cluster is built with the desired configuration for networking, storage, compute etc. The [simple_hpc_pbs](https://github.com/Azure/azurehpc/tree/eda/examples/simple_hpc_pbs) template in the examples directory is a suitable choice. 

After cluster is built, first copy the apps directory to the cluster.  The `azhpc-scp` can be used to do this:

```
azhpc-scp -u hpcuser -r $azhpc_dir/apps hpcuser@headnode:.
```

Then connect to the headnode:
```
azhpc-connect -u hpcuser headnode
```
Or simply create a Azure Virtual machine with CentOS and ssh connect to it.

## Install BLAST, download BlastDB, input file, query string

Take a look at the 'install_blast.sh' script, modify the installation directory if needed:
```
vim install_blast.sh
```

Run the 'install_blast.sh' script:
```
source install_blast.sh
```
## Run BLAST

Change folder to your BLAST installation directory
```
source test.sh
```

