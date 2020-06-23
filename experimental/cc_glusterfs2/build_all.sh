#!/bin/bash

azhpc-build -c vnet.json

blocks="jumpbox.json cycle-prereqs-managed-identity.json cycle-install-server-managed-identity.json cycle-cli-local.json cycle-cli-jumpbox.json gluster-cluster.json"
for block in $blocks; do
	    azhpc-build --no-vnet -c $block
done

azhpc ccbuild -c pbscycle.json
