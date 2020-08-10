#!/bin/bash

azhpc-scp -c ../config.json -- -r scripts/. hpcadmin@jumpbox:./azhpc_install_config/scripts/
