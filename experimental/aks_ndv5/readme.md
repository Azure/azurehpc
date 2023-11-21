# Run hpc-diagnostics and NHC on NDv5 AKS cluster  

Contains a Dockerfile and sample AKS manifest yaml files to run hpc-diagnostics and NHC on an AKS node.
 
## Prerequisites

- AKS cluster (NDv5) is deployed, see [blog post](https://techcommunity.microsoft.com/t5/azure-high-performance-computing/deploy-ndm-v4-a100-kubernetes-cluster/ba-p/3838871)
- Downloaded [ndv5-topo.xml](https://github.com/Azure/azhpc-images/blob/master/topology/ndv5-topo.xml) file
- Copy *.nhc, nccl-tests.sh and azurehpc-health-checks.sh from aks_ndv4
- You will need to replace the image referred in the nhc.yaml file (The one created using the Dockerfile). The hpc-diagnostics.yaml image does not need to be changed.
- Make sure the MOFED dirver version on the AKS hosting OS is compatibile with the nvidia-utils package being installed.


>Note: hpc-diagnostics tarball will be deposited on the AKS host in /tmp
