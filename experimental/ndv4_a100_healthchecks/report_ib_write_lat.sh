#!/bin/bash
  
grep  "2  " out/*.log | sort -n -k 5
