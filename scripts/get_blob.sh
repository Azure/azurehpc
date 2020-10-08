#!/bin/bash
folder_sasurl=$1 # this is the sasurl of the folder containing the blob
blob_name=$2 # a single blob name, it can also be * for all blobs in that folder
destination=$3 # destination folder or full name

folder=$(echo $folder_sasurl | cut -d'?' -f1)
saskey=$(echo $folder_sasurl | cut -d'?' -f2)

azcopy cp "$folder/$blob_name?$saskey" $destination
