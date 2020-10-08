#!/bin/bash
blob=$1
dest=$2

azcopy cp "$1" "$2"