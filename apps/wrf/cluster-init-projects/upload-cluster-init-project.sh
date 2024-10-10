#!/bin/bash

project_folder_name="wrf-proj"
# check locker name:
#cyclecloud locker list
locker_name="GBB HPC-storage"

echo "Uploading project $project_folder_name to locker $locker_name"

cd $project_folder_name

# Upload project
cyclecloud project upload "$locker_name"

echo "Project $project_folder_name uploaded to locker $locker_name"