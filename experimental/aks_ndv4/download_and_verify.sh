#!/bin/bash
set -ex

DOWNLOAD_URL=$1
DOWNLOADED_FILE_NAME=$(basename $1)
FILE_CHECKSUM=$2

# Find and verify checksum
verify_checksum() {
    local checksum=`sha256sum $1 | awk '{print $1}'`
    if [[ $checksum == $2 ]]
    then
        echo "Checksum verified!"
    else
        echo "*** Error - Checksum verification failed"
        exit -1
    fi
}

if [ $# -eq 2 ]
then
    wget --retry-connrefused --tries=3 --waitretry=5 $DOWNLOAD_URL
    verify_checksum $(readlink -f $DOWNLOADED_FILE_NAME) $FILE_CHECKSUM
else
    echo "*** Error - Invalid inputs!"
    exit -1
fi

exit 0
