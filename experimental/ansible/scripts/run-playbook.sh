#!/bin/bash
hosts=$1

ansible-playbook -i $hosts cluster.yml