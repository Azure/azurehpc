#!/bin/bash

lsadmin limstartup -f
lsadmin resstartup -f
badmin hstartup -f

# get info from setup
lsid

# List clusters
lsclusters

# List queues
bqueues

# List hosts
bhosts
lshosts
