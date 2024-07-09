# Integrate HPC/AI cluster monitoring with AKS 

Shows how to run custom HPC/AI cluster  monitoring (IB, GPU, CPU, Disks etc) with AKS
 
## Prerequisites

- AKS cluster (NDmv4) is deployed, see [blog post](https://techcommunity.microsoft.com/t5/azure-high-performance-computing/deploy-ndm-v4-a100-kubernetes-cluster/ba-p/3838871)
- You have a log analytics workspace.
- DCGM Exporter (in GPU operator) is disabled ( dcgmExporter.enabled=false)
- You will need to replace all references to \<YOUR ACR\> , \<YOUR TAG\>, \<YOUR LOG ANALYTICS WORKSPACE ID\>, and \<YOUR LOG ANALYTICS KEY\> in the provided scripts. 

## Build hpc monitoring container image

```
docker build -t \<YOUR ACR\>.azurecr.io/aks-ai-monitoring:\<YOUR TAG\> .
docker d -t \<YOUR ACR\>.azurecr.io/aks-ai-monitoring:\<YOUR TAG\>
```

## Deploy HPC/AI Monitoring in AKS
```
kubectl apply -f log_analytics_secret_key.yaml
kubectl apply -f hpc-ai-monitor-config.yaml
kubectl apply -f hpc-ai-monitor.yaml
``` 
>Note: By default HPC/AI monitoring monitors IB & GPU (GPU Util, GPU mem & GPU tensor core), metrics collected every 10 sec. You can change what is monitored by modifying hpc-ai-monitor-config.yaml.
