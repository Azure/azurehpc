#!/bin/bash

apt install -y sudo bc
git clone https://github.com/Azure/azurehpc-health-checks.git

cp azure_nccl_allreduce.nhc /workspace/azurehpc-health-checks/customTests
cp azure_nccl_allreduce_ib_loopback.nhc /workspace/azurehpc-health-checks/customTests
cp azure_ib_write_bw_gdr.nhc /workspace/azurehpc-health-checks/customTests
cd /workspace/azurehpc-health-checks
chmod 775 install-nhc.sh
chmod 775 distributed_nhc.sb.sh
chmod 775 run-health-checks.sh
chmod 775 customTests/custom-test-setup.sh

./install-nhc.sh
cd /workspace
