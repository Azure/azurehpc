#!/bin/bash
yum-config-manager --add-repo https://opm-project.org/package/opm.repo
yum install -y resinsight
yum install -y resinsight-octave

yum install -y qt5-qtbase-gui qt5-qtscript qt5-qtsvg