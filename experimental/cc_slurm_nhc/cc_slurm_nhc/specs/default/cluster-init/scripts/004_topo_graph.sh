#!/bin/bash

if ! [ -d /opt/microsoft/ncv4 ]; then
   mkdir /opt/microsoft/ncv4
fi

cp $CYCLECLOUD_SPEC_PATH/files/nc48v4-topo.xml /opt/microsoft/ncv4
cp $CYCLECLOUD_SPEC_PATH/files/nc48v4-graph.xml /opt/microsoft/ncv4
