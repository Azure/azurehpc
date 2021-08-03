#!/bin/bash

sudo mkdir /mnt/resource_nvme
sudo mdadm --create /dev/md10 --level 0 --raid-devices 2 /dev/nvme0n1 /dev/nvme1n1
sudo mkfs.xfs /dev/md10
sudo mount /dev/md10 /mnt/resource_nvme
sudo chmod 1777 /mnt/resource_nvme
