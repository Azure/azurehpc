#!/bin/bash

sed -i 's/# OS.EnableRDMA=y/OS.EnableRDMA=y/g' /etc/waagent.conf 
service waagent restart 
service rdma start
modprobe lnet 
lctl network configure 
lnetctl net add --net o2ib --if ib0 #need this to come up every time
sleep 5
