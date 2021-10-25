#!/bin/bash

grep 32000 out/*.out | sort -n -k 3
