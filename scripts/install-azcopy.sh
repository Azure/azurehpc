#!/bin/bash

cd /usr/local/bin
wget https://aka.ms/downloadazcopy-v10-linux -O - | tar zxf - --strip-components 1 --wildcards '*/azcopy'

