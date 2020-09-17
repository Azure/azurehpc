#!/bin/bash

if [ "$PSSH_NODENUM" = "0" ]; then

	lfs setstripe --stripe-count 8 --stripe-size 4M /lustre

fi
