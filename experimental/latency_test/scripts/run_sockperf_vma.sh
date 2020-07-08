#!/bin/bash

my_ip=$(nslookup comp0 | grep ^Address: | tail -n1 | cut -f2 -d' ')

sudo LD_PRELOAD=libvma.so VMA_SPEC=latency sockperf sr --tcp -i $my_ip -p 12345 &
ssh comp1 "sudo LD_PRELOAD=libvma.so VMA_SPEC=latency sockperf ping-pong -i $my_ip --tcp -m 350 -t 101 -p 12345 --full-rtt"

while proc_id=$(pgrep -x sockperf); do
    echo "killing sockperf"
    sudo kill $proc_id
    sleep 1
done

echo "finished script"
