#!/bin/bash
set -euo pipefail

MODULE_PATH=${1:-/apps/EasyBuild/modules/all/Core}

# Install Lmod
sudo yum install -y epel-release
sudo yum install -y Lmod

# Remove all paths in MODULEPATHS set by Environment Modules
sudo sed -i 's/MODULEPATH_INIT.*then/&\n       unset MODULEPATH/g' /etc/profile.d/z00_lmod.sh
sudo sed -i 's/MODULEPATH_INIT.*then/&\n        unsetenv MODULEPATH/g' /etc/profile.d/z00_lmod.csh

# Add modules root path to MODULEPATH
printf '\nUsing %s as default module path.\n' ${MODULE_PATH}
printf 'If wrong, please change it at /usr/share/lmod/lmod/init/.modulespath\n\n'
echo ${MODULE_PATH} | sudo tee /usr/share/lmod/lmod/init/.modulespath > /dev/null
