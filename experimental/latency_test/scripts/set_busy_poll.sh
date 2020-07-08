#!/bin/bash

duration=$1

sysctl net.core.busy_poll=$duration
sysctl net.core.busy_read=$duration
