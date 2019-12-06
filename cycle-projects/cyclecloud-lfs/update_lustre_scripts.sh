#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ "$azhpc_dir" = "" ]; then

	echo "ERROR: azurehpc is not setup in the environment"
	echo
	echo "Steps to install:"
	echo
	echo "    git clone https://github.com/Azure/azurehpc.git"
	echo "    . azurehpc/install.sh"
	echo
	exit 1

fi


for full_path in specs/*/cluster-init/files/*.sh; do

	script_name=$(basename $full_path)
	if [ "$(diff -q $azhpc_dir/scripts/$script_name $full_path)" = "" ]; then
		echo "info: $full_path has not changed"
	else
		echo "info: updating $full_path"
		cp $azhpc_dir/scripts/$script_name $full_path
	fi

done

