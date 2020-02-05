#!/bin/bash
source "$azhpc_dir/libexec/common.sh"

DEBUG_ON=1
COLOR_ON=1
config_file="config.json"

read_value location ".location"
read_value resource_group ".resource_group"
read_value key_vault ".variables.key_vault"
read_value projectstore ".variables.projectstore"

read_value secret ".variables.secret1"
read_value secret ".variables.secret2"
read_value key ".variables.sakey2"
read_value key ".variables.sakey1"
read_value key ".variables.fqdn1"
read_value key ".variables.fqdn2"

read_value key ".variables.sasurl1"
read_value key ".variables.sasurl2"
read_value key ".variables.sasurl3"
read_value key ".variables.sasurl4"