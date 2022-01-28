#!/bin/bash

HOSTLIST=hostlist
PDSH_RCMD_TYPE=ssh


WCOLL=$HOSTLIST pdsh sudo pkill gpu_data_collector
