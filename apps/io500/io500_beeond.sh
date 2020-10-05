#!/bin/bash
IOR_EASY_STRIPE=1
IOR_EASY_CHUNKSIZE=2m
IOR_HARD_STRIPE=$AZHPC_NODES
IOR_HARD_CHUNKSIZE=2m

function setup_directories {
  local workdir
  local resultdir
  local ts

  # set directories where benchmark files are created and where the results go
  # If you want to set up stripe tuning on your output directories or anything
  # similar, then this is the right place to do it.  This creates the output
  # directories for both the app run and the script run.

  timestamp=$(date +%Y.%m.%d-%H.%M.%S)           # create a uniquifier
  [ $(get_ini_global_param timestamp-datadir True) != "False" ] &&
        ts="$timestamp" || ts="io500"
  # directory where the data will be stored
  workdir=$(get_ini_global_param datadir $PWD/datafiles)/$ts
  io500_workdir=$workdir-scr
  [ $(get_ini_global_param timestamp-resultdir True) != "False" ] &&
        ts="$timestamp" || ts="io500"
  # the directory where the output results will be kept
  resultdir=$(get_ini_global_param resultdir $PWD/results)/$ts
  io500_result_dir=$resultdir-scr

  mkdir -p $workdir-{scr,app} $resultdir-{scr,app}
  mkdir -p $workdir-{scr,app}/{ior_easy,ior_hard,mdt_easy,mdt_hard}

  # for ior_easy.
  sudo beegfs-ctl --mount=/beeond --setpattern --chunksize=$IOR_EASY_CHUNKSIZE --numtargets=$IOR_EASY_STRIPE $workdir-scr/ior_easy
  sudo beegfs-ctl --mount=/beeond --setpattern --chunksize=$IOR_EASY_CHUNKSIZE --numtargets=$IOR_EASY_STRIPE $workdir-app/ior_easy

  # stripe across all OSTs for ior_hard, 256k chunksize
  sudo beegfs-ctl --mount=/beeond --setpattern --chunksize=$IOR_HARD_CHUNKSIZE --numtargets=$IOR_HARD_STRIPE $workdir-scr/ior_hard
  sudo beegfs-ctl --mount=/beeond --setpattern --chunksize=$IOR_HARD_CHUNKSIZE --numtargets=$IOR_HARD_STRIPE $workdir-app/ior_hard

  # turn off striping and use small chunks for mdtest
  sudo beegfs-ctl --mount=/beeond --setpattern --chunksize=64k --numtargets=1 $workdir-scr/mdt_easy
  sudo beegfs-ctl --mount=/beeond --setpattern --chunksize=64k --numtargets=1 $workdir-scr/mdt_hard

  sudo beegfs-ctl --mount=/beeond --setpattern --chunksize=64k --numtargets=1 $workdir-app/mdt_easy
  sudo beegfs-ctl --mount=/beeond --setpattern --chunksize=64k --numtargets=1 $workdir-app/mdt_hard

}