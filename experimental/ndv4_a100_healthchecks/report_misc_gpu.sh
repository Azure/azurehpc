#!/bin/bash

grep num_gpus out/*.out | sort -n -k 2
