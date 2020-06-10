#!/bin/bash

curl -s -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2018-10-01"
