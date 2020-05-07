#!/bin/bash
set -ex

account=$1
container=$2
blob=$3
sasurl="$4"
sakey="$5"
saskey="$6"

echo "Download blob with SASURL"
wget "$sasurl" -o blob_sasurl.txt
cat blob_sasurl.txt

echo "Download blob with sakey"
az storage blob download -c $container -n $blob -f blob_sakey.txt --account-name $account --account-key $sakey
cat blob_sakey.txt

echo "Download blob with saskey"
az storage blob download -c $container -n $blob -f blob_saskey.txt --account-name $account --sas-token $saskey
cat blob_saskey.txt

