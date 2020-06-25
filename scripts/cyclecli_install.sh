#!/bin/bash
set -e
fqdn=$1
admin_user=$2
password=$3
cc_version=${4-7}

# Installing CycleCloud CLI
echo "Getting CLI binaries..."
case "$cc_version" in
    7)
        wget -q --no-check-certificate https://$fqdn/download/tools/cyclecloud-cli.zip 
        ;;
    8)
        wget -q --no-check-certificate https://$fqdn/static/tools/cyclecloud-cli.zip 
        ;;
    *)
        echo "Version $cc_version not supported"
        exit 1
        ;;
esac

unzip -o cyclecloud-cli.zip
pushd cyclecloud-cli-installer/


echo "Installing CLI..."
# If az CLI is installed used the bundled version
python_path=$(az --version | grep 'Python location' | xargs | cut -d' ' -f3)
if [ -n "$python_path" ]; then
    $python_path install.py -y
else
    if ! rpm -q python3; then
        sudo yum install -y python3
    fi
    ./install.sh -y
fi


echo "Initializing CLI..."
name=$(echo $fqdn | cut -d'.' -f1)
echo $name
~/bin/cyclecloud initialize --force --batch \
    --name $name \
    --url=https://$fqdn \
    --verify-ssl=false \
    --username=$admin_user \
    --password="${password}"

~/bin/cyclecloud config list
popd
rm cyclecloud-cli.zip
rm -rf cyclecloud-cli-installer
