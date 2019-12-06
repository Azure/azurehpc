Detailed documentation on how to run these health checks on HB and HC can be found [here](https://techcommunity.microsoft.com/t5/AzureCAT/Health-checks-for-HPC-workloads-on-Microsoft-Azure/ba-p/837843)

To run stream tests on HB/HC:
azhpc-scp -r $azhpc_dir/apps hpcadmin@headnode:
azhpc-run -n headnode apps/health_checks/install_stream_test.sh
azhpc-run -n compute /data/node_utils/Stream/stream_test.sh
