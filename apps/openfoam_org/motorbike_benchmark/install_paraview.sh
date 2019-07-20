#!/bin/bash

INSTALL_DIR=/apps
cd /apps

wget "https://www.paraview.org/paraview-downloads/download.php?submit=Download&version=v5.6&type=binary&os=Linux&downloadFile=ParaView-5.6.1-osmesa-MPI-Linux-64bit.tar.gz" -O - | tar zxf -
