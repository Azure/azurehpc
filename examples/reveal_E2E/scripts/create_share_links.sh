#!/bin/bash

if [ ! -L /share/apps ]
then
ln -s /apps /share/apps
ln -s /data /share/data
fi
