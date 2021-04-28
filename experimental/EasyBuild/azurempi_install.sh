#!/bin/bash
set -euo pipefail

THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Find stack installation prefix
ml EasyBuild
STACK_PREFIX=$(echo $EBROOTEASYBUILD | rev | cut -d'/' -f4- | rev)

# Copy custom easyblocks and easyconfigs in stack prefix directory 
cp -rv ${THIS_SCRIPT_DIR}/custom_easyblocks  ${THIS_SCRIPT_DIR}/custom_easyconfigs ${STACK_PREFIX}

# Find EasyBuild configuration file path
EBCONF_FILE=$(eb --show-default-configfiles | grep -A1 system-level | tail -1 | awk -F'>' '{print $3}')

# Make EasyBuild aware of the new AzureMPI easyblock
# If include-easyblocks option already exists in configure file, prepend to existing paths
# otherwise add it right after "[config]" section marker
grep -q 'include-easyblocks' ${EBCONF_FILE} && \
sed -i -e "/^\(include-easyblocks = \)\(.*\)/{s//\1${STACK_PREFIX}/custom_easyblocks/azurempi.py,\2/}" ${EBCONF_FILE} || \
sed -i -e "/^\[config\].*/a include-easyblocks = ${STACK_PREFIX}/custom_easyblocks/azurempi.py" ${EBCONF_FILE}

# Instruct EasyBuild robot to search custom easyconfigs directory before easyconfigs included with EB installation
cat << EOF >> $EBCONF_FILE
[basic]
robot-paths = ${STACK_PREFIX}/custom_easyconfigs:
EOF
