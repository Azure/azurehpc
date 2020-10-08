#!/bin/bash

DARSHAN_IO_PROFILE=$1
FILESYSTEM=$2


function get_json_value() {
   jq_filter=$1
   eval $(tr -s . _ <<< $jq_filter)=$(jq .$jq_filter $DARSHAN_IO_PROFILE)
}

function get_transfersize_percent() {
   IO_TYPE="write. read."
   TRANSFERSIZE_RANGES="R_0_100 R_100_1K R_1K_10K R_10K_100K R_100K_1M R_1M_4M \
                        R_4M_10M R_10M_100M R_100M_1G R_1G_PLUS"
   for range in $TRANSFERSIZE_RANGES
   do
      for type in  $IO_TYPE
         do
         get_json_value "transfersize_percentage."${type}${range}
         done
   done
}

function choose_write_transfersize() {

   pts_list="$transfersize_percentage_write_R_0_100 $transfersize_percentage_write_R_100_1K \
                   $transfersize_percentage_write_R_1K_100K $transfersize_percentage_write_R_100K_1M \
                   $transfersize_percentage_write_R_1M_4M $transfersize_percentage_write_R_4M_10M \
                   $transfersize_percentage_write_R_10M_100M $transfersize_percentage_write_R_100M_1G \
                   $transfersize_percentage_write_R_1G_PLUS"
   arrts=(32 512 5120 51200 512000 2097152 6291456 31457280 524288000 1073741824)
   
   max_pts=0
   cnt=0
   for pts in $pts_list
   do
      if [ $pts -gt $max_pts ]; then
         max_pts=$pts
         indx=$cnt
      fi
      cnt=$((cnt+1))
   done
   TRANSFER_SIZE_WRITE=${arrts[$indx]}"K"
}

function choose_read_transfersize() {

   pts_list="$transfersize_percentage_read_R_0_100 $transfersize_percentage_read_R_100_1K \
                  $transfersize_percentage_read_R_1K_100K $transfersize_percentage_read_R_100K_1M \
                  $transfersize_percentage_read_R_1M_4M $transfersize_percentage_read_R_4M_10M \
                  $transfersize_percentage_read_R_10M_100M $transfersize_percentage_read_R_100M_1G \
                  $transfersize_percentage_read_R_1G_PLUS"
   arrts=(32 512 5120 51200 512000 2097152 6291456 31457280 524288000 1073741824)
   
   max_pts=0
   cnt=0
   for pts in $pts_list
   do
      if [ $pts -gt $max_pts ]; then
         max_pts=$pts
         indx=$cnt
      fi
      cnt=$((cnt+1))
   done
   TRANSFER_SIZE_READ=${arrts[$indx]}"K"
}

function choose_ior_api() {
   get_json_value "file_type_percentage.unique"
   get_json_value "file_type_percentage.shared"
   if [ $file_type_percentage_unique -gt $file_type_percentage_shared ]; then
       IO_API="POSIX"
       IO_API_ARG="-F"
   else
       IO_API_ARG=""
       IO_API="MPIIO"
   fi
}



function choose_ior_blocksize() {
   MIN_BLOCKSIZE_MIB=512
   get_json_value "data_transferred.total_bytes_transferred_MiB"
   get_json_value "data_transferred.percentage.write"
   get_json_value "data_transferred.percentage.read"
   data_transferred_write_MiB=$(bc <<< "($data_transferred_total_bytes_transferred_MiB * \
                                      $data_transferred_percentage_write) / 100.0")
   data_transferred_read_MiB=$(bc <<< "$data_transferred_total_bytes_transferred_MiB - \
                                       $data_transferred_write_MiB")
   blocksize_wite_MiB=$(bc <<< "$data_transferred_write_MiB / $nprocs")
   blocksize_read_MiB=$(bc <<< "$data_transferred_read_MiB / $nprocs")
   BLOCKSIZE_WRITE_MiB=$((blocksize_wite_MiB>MIN_BLOCKSIZE_MIB ? blocksize_wite_MiB : MIN_BLOCKSIZE_MIB))"M" 
   BLOCKSIZE_READ_MiB=$((blocksize_read_MiB>MIN_BLOCKSIZE_MIB ? blocksize_read_MiB : MIN_BLOCKSIZE_MIB))"M" 
}

get_json_value nprocs
get_transfersize_percent
choose_write_transfersize
choose_read_transfersize
choose_ior_api
choose_ior_blocksize

export nprocs
export TRANSFER_SIZE_WRITE
export TRANSFER_SIZE_READ
export IO_API
export IO_API_ARG
export BLOCKSIZE_WRITE_MiB
export BLOCKSIZE_READ_MiB
export FILESYSTEM

qsub -l select=1:ncpus=120:mpiprocs=$nprocs -V ./run_generated_ior.pbs
