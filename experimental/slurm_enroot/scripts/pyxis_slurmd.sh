#!/bin/bash

cp -v /apps/slurm/spank_pyxis.so /usr/lib64/slurm/
chmod +x /usr/lib64/slurm/spank_pyxis.so

echo Restarting SLURMD...
systemctl restart slurmd