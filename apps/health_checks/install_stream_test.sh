#!/bin/bash

BASE_DIR=/data/node_utils
mkdir -p $BASE_DIR

cd $BASE_DIR
wget https://azhpcscus.blob.core.windows.net/apps/Stream/stream.tgz
tar xzvf stream.tgz
