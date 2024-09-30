#!/bin/bash

template_name="Slurm-WRF"
template_file="/anf-vol1/wrf/data/azurehpc/apps/wrf/cluster-init-projects/wrf-proj/templates/slurm-wrf-template-login-node.txt"

echo "Importing template $template_name from $template_file"

# Import template
cyclecloud import_template $template_name -f $template_file --force

echo "Template $template_name imported"	
