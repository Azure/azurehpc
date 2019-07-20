#!/bin/bash
cd /tmp

apps_dir=/apps
if [ ! -d "$apps_dir" ]; then
    apps_dir=/share/apps
fi

install_dir=$apps_dir/resinsight
mkdir -p $install_dir

echo "Ready to download the install file"
wget -q https://github.com/OPM/ResInsight/releases/download/v2019.04/ResInsight-2019.04.0_oct-4.0.0_souring_win64.zip  

echo "Ready to install"
unzip -d $install_dir ResInsight-2019.04.0_oct-4.0.0_souring_win64.zip

echo "Remove the install file"
rm -f /tmp/ResInsight-2019.04.0_oct-4.0.0_souring_win64.zip
