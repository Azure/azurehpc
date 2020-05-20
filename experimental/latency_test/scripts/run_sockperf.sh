#!/bin/bash

my_ip=$(nslookup comp0 | grep ^Address: | tail -n1 | cut -f2 -d' ')

sockperf sr --tcp -i $my_ip -p 12345 &
ssh comp1 sockperf ping-pong -i $my_ip --tcp -m 350 -t 101 -p 12345 --full-rtt
kill %1
