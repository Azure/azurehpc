#!/bin/bash

if [ -f scripts/rhel_iotest.sh ]; then
    echo "Script already exists (scripts/rhel_iotest.sh).  Exiting."
    exit 0
fi

# download from sas site
wget http://ftp.sas.com/techsup/download/ts-tools/external/SASTSST_UNIX_installation.sh

# extract rhel_iotest.sh
bash ./SASTSST_UNIX_installation.sh <<EOF
yes
$(pwd)/scripts
3
EOF

# delete full bundle
rm SASTSST_UNIX_installation.sh

# patch script
echo "patching script to enable running on multiple hosts concurrently"
sed -i 's/SPROG="rhel_iotest"/SPROG="rhel_iotest_\$\(hostname\)"/g' scripts/rhel_iotest.sh

