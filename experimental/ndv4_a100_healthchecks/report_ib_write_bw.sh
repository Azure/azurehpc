#!/bin/bash

grep 1048576 out/*.log | sort -n -k 5
