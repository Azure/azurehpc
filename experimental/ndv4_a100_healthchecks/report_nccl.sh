#!/bin/bash

grep "  8589934592  " out/*.log* | sort -n -k 7
