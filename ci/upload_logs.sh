#!/bin/bash
# Upload azhpc logs into blob storage
FOLDER_TO_UPLOAD=$1
BLOB=$2

echo "===================="
echo "Upload logs in blobs"
echo "===================="
echo ""
echo "upload $FOLDER_TO_UPLOAD into blobs"
account="$AZHPC_LOG_ACCOUNT"
container="pipelines"
saskey=$( \
    az storage container generate-sas \
    --account-name $account \
    --name $container \
    --permissions "rlw" \
    --start $(date --utc -d "-2 hours" +%Y-%m-%dT%H:%M:%SZ) \
    --expiry $(date --utc -d "+1 hour" +%Y-%m-%dT%H:%M:%SZ) \
    --output tsv
)
echo "azcopy cp $FOLDER_TO_UPLOAD https://$account.blob.core.windows.net/$container/$BLOB?$saskey --recursive=true"
azcopy cp "$FOLDER_TO_UPLOAD" "https://$account.blob.core.windows.net/$container/$BLOB?$saskey" --recursive=true
