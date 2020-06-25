#!/bin/bash

sudo waagent -force -deprovision+user
export HISTSIZE=0
sync

