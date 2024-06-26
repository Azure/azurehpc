# Integration of GPU node health checks into AKS  

Show how to integrate the azurehpc-health-checks GPU tests in k8s node problem detector and then use draino to cordon/drain nodes based on GPU healthc check conditions.
 
## Prerequisites

- AKS cluster (NDmv4) is deployed, see [blog post](https://techcommunity.microsoft.com/t5/azure-high-performance-computing/deploy-ndm-v4-a100-kubernetes-cluster/ba-p/3838871)
- You will need to replace all references to \<YOUR ACR\> and \<YOUR TAG\>  in these scripts.

## Build NPD
- Use modified NPD Makefile and Dockerfile to build NPD
```
BUILD_TAGS="disable_system_log_monitor disable_system_stats_monitor" make 2>&1 | tee make.out
```
```
make push
```
>Note: Only a few GPU tests are included, other tests can be easily added.

## Build draino
```
docker build -t <YOUR ACR>.azurecr.io/draino .
docker push <YOUR ACR>.azurecr.io/draino
```

## Deploy NPD
```
kubectl apply -f rbac.yaml
kubectl apply -f node-problem-detector-config.yaml
kubectl apply -f node-problem-detector.yaml
``` 

## Deploy Draino
```
kubectl apply -f manifest.yml
```
