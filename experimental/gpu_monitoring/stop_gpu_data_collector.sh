#!/bin/bash

HOSTLIST=hostlist
PDSH_RCMD_TYPE=ssh


WCOLL=$HOSTLIST pdsh sudo mv /etc/crontab.orig /etc/crontab
