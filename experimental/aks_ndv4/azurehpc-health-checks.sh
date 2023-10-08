#!/bin/bash

apt install -y sudo
git clone https://github.com/Azure/azurehpc-health-checks.git

cp custom-test-setup.sh /workspace/azurehpc-health-checks/customTests/custom-test-setup.sh
cp azure_nccl_allreduce.nhc /workspace/azurehpc-health-checks/customTests
cp azure_nccl_allreduce_ib_loopback.nhc /workspace/azurehpc-health-checks/customTests
cd /workspace/azurehpc-health-checks
chmod 775 install-nhc.sh
chmod 775 distributed_nhc.sb.sh
chmod 775 run-health-checks.sh
chmod 775 customTests/custom-test-setup.sh

./install-nhc.sh
cd /workspace
