#!/bin/bash

cd /usr/local/bin
wget -q https://aka.ms/downloadazcopy-v10-linux -O - | tar zxf - --strip-components 1 --wildcards '*/azcopy'
chmod +x /usr/local/bin/azcopy 
