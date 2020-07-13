#!/bin/bash

yum install -y nmap-ncat
yum install -y epel-release
yum install -y https://netix.dl.sourceforge.net/project/turbovnc/2.2.5/turbovnc-2.2.5.x86_64.rpm
yum install -y https://cbs.centos.org/kojifiles/packages/python-websockify/0.8.0/13.el7/noarch/python2-websockify-0.8.0-13.el7.noarch.rpm

yum install -y libXcomposite libXcursor libXi libXtst libXrandr alsa-lib mesa-libEGL libXdamage mesa-libGL libXScrnSaver
yum install -y python-pip
pip install --upgrade pip
pip install jupyter

yum install -y Lmod

yum group install -y 'Development Tools'
yum install -y perl-core zlib-devel
yum install -y openssl openssl-devel openssl-libs

