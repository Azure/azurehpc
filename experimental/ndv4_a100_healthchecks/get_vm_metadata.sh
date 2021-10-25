#!/bin/bash

HOSTNAME=`hostname`
OUT_DIR=/shared/home/cycleadmin/healthchecks/vm_metadata

curl -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance?api-version=2021-02-01" | jq '.' >& ${OUT_DIR}/${HOSTNAME}_metadata.out
