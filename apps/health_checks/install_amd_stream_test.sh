#!/bin/bash

BASE_DIR=/data/node_utils/HB
mkdir -p $BASE_DIR

cd $BASE_DIR
wget https://azhpcscus.blob.core.windows.net/apps/Stream/AMD/hb_stream.tgz
tar xzvf hb_stream.tgz
cd Stream
wget https://azhpcscus.blob.core.windows.net/apps/Stream/AMD/hb_stream_test.sh
