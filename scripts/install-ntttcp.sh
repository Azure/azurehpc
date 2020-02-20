#!/bin/bash

yum install gcc -y
yum install git -y

git clone https://github.com/Microsoft/ntttcp-for-linux
cd ntttcp-for-linux/src
make && make install

