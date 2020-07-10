#!/bin/bash

yum install -y nmap-ncat
yum install -y epel-release
yum groupinstall -y "X Window system"
yum groupinstall -y xfce
yum install -y https://netix.dl.sourceforge.net/project/turbovnc/2.2.5/turbovnc-2.2.5.x86_64.rpm
yum install -y https://cbs.centos.org/kojifiles/packages/python-websockify/0.8.0/13.el7/noarch/python2-websockify-0.8.0-13.el7.noarch.rpm
