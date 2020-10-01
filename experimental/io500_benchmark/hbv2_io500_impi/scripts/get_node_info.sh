#!/bin/bash

curl -s -H Metadata:true "http://169.254.169.254/metadata/instance/compute?api-version=2019-08-15"
