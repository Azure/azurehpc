#!/bin/bash

DARSHAN_FILE_PATH=$1

DARSHAN_IO_PROFILE_NAME=darshan_io_profile

POSIX_VALUES_TO_EXTRACT="POSIX_READS POSIX_WRITES POSIX_SEEKS POSIX_BYTES_READ POSIX_BYTES_WRITTEN POSIX_CONSEC_READS POSIX_CONSEC_WRITES POSIX_SEQ_READS POSIX_SEQ_WRITES POSIX_SIZE_READ_0_100 POSIX_SIZE_READ_100_1K POSIX_SIZE_READ_1K_10K POSIX_SIZE_READ_10K_100K POSIX_SIZE_READ_100K_1M POSIX_SIZE_READ_1M_4M POSIX_SIZE_READ_4M_10M POSIX_SIZE_READ_10M_100M POSIX_SIZE_READ_100M_1G POSIX_SIZE_READ_1G_PLUS POSIX_SIZE_WRITE_0_100 POSIX_SIZE_WRITE_100_1K POSIX_SIZE_WRITE_1K_10K POSIX_SIZE_WRITE_10K_100K POSIX_SIZE_WRITE_100K_1M POSIX_SIZE_WRITE_1M_4M POSIX_SIZE_WRITE_4M_10M POSIX_SIZE_WRITE_10M_100M POSIX_SIZE_WRITE_100M_1G POSIX_SIZE_WRITE_1G_PLUS POSIX_F_READ_TIME POSIX_F_WRITE_TIME POSIX_F_META_TIME"
STDIO_VALUES_TO_EXTRACT="STDIO_READS STDIO_WRITES STDIO_SEEKS STDIO_BYTES_READ STDIO_BYTES_WRITTEN STDIO_F_META_TIME STDIO_F_WRITE_TIME STDIO_F_READ_TIME"

spack load darshan-util
darshan-parser --total $DARSHAN_FILE_PATH > /tmp/darshan_parser_total.out_$$
darshan-parser --file  $DARSHAN_FILE_PATH > /tmp/darshan_parser_file.out_$$
darshan-parser --perf  $DARSHAN_FILE_PATH > /tmp/darshan_parser_perf.out_$$


function get_total_wtime() {
   TOTAL_WTIME=$(awk '/run time/ { print $4 }' $1)
}

function get_total() {
   eval TOTAL_$2=$(awk -v param=total_$2 '$0~param { print $2 }' $1)
}

function calc_total_number_files() {
   TOTAL_NUMBER_FILES=0
   for FILE_COUNT in `awk '/# total:/ { print $3 }' $1`
   do
      TOTAL_NUMBER_FILES=$((TOTAL_NUMBER_FILES+FILE_COUNT))
   done
}

function get_performance_posix_stdio() {
   arrStr=("POSIX" "STDIO")
   cnt=0
   for PERFORMANCE in `awk '/# agg_perf_by_slowest:/ { print $3 }' $1`
   do
      eval TOTAL_${arrStr[$cnt]}_MiBps=$PERFORMANCE
      cnt=$((cnt+1))
   done
}

function calc_total_transferred_read_write() {
   TOTAL_BYTES_TRANSFERRED_READ=$(bc <<< "$TOTAL_POSIX_BYTES_READ + \
                                          $TOTAL_STDIO_BYTES_READ") 
   TOTAL_BYTES_TRANSFERRED_WRITE=$(bc <<< "$TOTAL_POSIX_BYTES_WRITTEN + \
                                           $TOTAL_STDIO_BYTES_WRITTEN")
}

function calc_total_bytes_transferred() {
   TOTAL_BYTES_TRANSFERRED=$(bc <<< "$TOTAL_BYTES_TRANSFERRED_READ + $TOTAL_BYTES_TRANSFERRED_WRITE")
   TOTAL_BYTES_TRANSFERRED_MiB=$(bc <<< "$TOTAL_BYTES_TRANSFERRED / (1024 * 1024)")
}

function calc_percent_transferred_read_write() {
   TOTAL_PERCENT_TRANSFERRED_READ=$(bc <<< "($TOTAL_POSIX_BYTES_READ * 100.0) / \
                                             $TOTAL_BYTES_TRANSFERRED")
   TOTAL_PERCENT_TRANSFERRED_WRITE=$(bc <<< "100.0 - $TOTAL_PERCENT_TRANSFERRED_READ")
}

function calc_transfer_rate_read_write() {
   TOTAL_TRANSFER_RATE_MiBps_READ=$(bc <<< "$TOTAL_BYTES_TRANSFERRED_READ / \
                                           ($TOTAL_WTIME_READ * 1024 * 1024)")
   TOTAL_TRANSFER_RATE_MiBps_WRITE=$(bc <<< "$TOTAL_BYTES_TRANSFERRED_WRITE / \
                                            ($TOTAL_WTIME_WRITE * 1024 * 1024)")
}

function calc_percent_transfersize_read_write() {
   array_total_POSIX_SIZE_READ_RANGE=($TOTAL_POSIX_SIZE_READ_0_100 $TOTAL_POSIX_SIZE_READ_100_1K \
                                      $TOTAL_POSIX_SIZE_READ_1K_10K $TOTAL_POSIX_SIZE_READ_10K_100K \
                                      $TOTAL_POSIX_SIZE_READ_100K_1M $TOTAL_POSIX_SIZE_READ_1M_4M \
                                      $TOTAL_POSIX_SIZE_READ_4M_10M $TOTAL_POSIX_SIZE_READ_10M_100M \
                                      $TOTAL_POSIX_SIZE_READ_100M_1G $TOTAL_POSIX_SIZE_READ_1G_PLUS)
   array_total_POSIX_SIZE_WRITE_RANGE=($TOTAL_POSIX_SIZE_WRITE_0_100 $TOTAL_POSIX_SIZE_WRITE_100_1K \
                                       $TOTAL_POSIX_SIZE_WRITE_1K_10K $TOTAL_POSIX_SIZE_WRITE_10K_100K \
                                       $TOTAL_POSIX_SIZE_WRITE_100K_1M $TOTAL_POSIX_SIZE_WRITE_1M_4M \
                                       $TOTAL_POSIX_SIZE_WRITE_4M_10M $TOTAL_POSIX_SIZE_WRITE_10M_100M \
                                       $TOTAL_POSIX_SIZE_WRITE_100M_1G $TOTAL_POSIX_SIZE_WRITE_1G_PLUS)
   cnt=0
   for RANGE in 0_100 100_1K 1K_10K 10K_100K 100K_1M 1M_4M 4M_10M 10M_100M 100M_1G 1G_PLUS
   do
      eval TOTAL_PERCENT_POSIX_SIZE_READ_$RANGE=$(bc <<< "(${array_total_POSIX_SIZE_READ_RANGE[$cnt]} * 100) / \
                                                            $TOTAL_POSIX_READS")
      eval TOTAL_PERCENT_POSIX_SIZE_WRITE_$RANGE=$(bc <<< "(${array_total_POSIX_SIZE_WRITE_RANGE[$cnt]} * 100) / \
                                                            $TOTAL_POSIX_WRITES")
     cnt=$((cnt+1))
   done
}

function calc_total_wtime_read_write_meta() {
   TOTAL_WTIME_READ=$(bc <<< "$TOTAL_POSIX_F_READ_TIME + $TOTAL_STDIO_F_READ_TIME") 
   TOTAL_WTIME_WRITE=$(bc <<< "$TOTAL_POSIX_F_WRITE_TIME + $TOTAL_STDIO_F_WRITE_TIME") 
   TOTAL_WTIME_META=$(bc <<< "$TOTAL_POSIX_F_META_TIME + $TOTAL_STDIO_F_META_TIME") 
}

function calc_total_io_wtime() {
   TOTAL_IO_WTIME=$(bc <<< "$TOTAL_WTIME_READ + $TOTAL_WTIME_WRITE + $TOTAL_WTIME_META") 
}

function calc_total_percent_io_wtime() {
   TOTAL_PERCENT_IO_WTIME=$(bc <<< "($TOTAL_IO_WTIME * 100.0) / $TOTAL_WTIME") 
}

function calc_total_iopts_read_write() {
   TOTAL_IOPTS_READ=$(bc <<< "$TOTAL_POSIX_READS / $TOTAL_POSIX_F_READ_TIME") 
   TOTAL_IOPTS_WRITE=$(bc <<< "$TOTAL_POSIX_WRITES / $TOTAL_POSIX_F_WRITE_TIME") 
}

function calc_total_iopts() {
   TOTAL_IOPTS=$(bc <<< "$TOTAL_IOPTS_READ + $TOTAL_IOPTS_WRITE") 
}

function calc_total_percent_iopts_read_write() {
   TOTAL_PERCENT_IOPTS_READ=$(bc <<< "($TOTAL_IOPTS_READ * 100.0) / $TOTAL_IOPTS") 
   TOTAL_PERCENT_IOPTS_WRITE=$(bc <<< "100.0 - $TOTAL_PERCENT_IOPTS_READ") 
}

function calc_percent_io_pattern() {
   TOTAL_PERCENT_CONSEC_READ=$(bc <<< "($TOTAL_POSIX_CONSEC_READS * 100.0) / $TOTAL_POSIX_READS") 
   TOTAL_PERCENT_CONSEC_WRITE=$(bc <<< "($TOTAL_POSIX_CONSEC_WRITES * 100.0) / $TOTAL_POSIX_WRITES") 
   TOTAL_PERCENT_SEQ_READ=$(bc <<< "($TOTAL_POSIX_SEQ_READS * 100.0) / $TOTAL_POSIX_READS") 
   TOTAL_PERCENT_SEQ_WRITE=$(bc <<< "($TOTAL_POSIX_SEQ_WRITES * 100.0) / $TOTAL_POSIX_WRITES")
   MAX_CONSEC_READ=$((TOTAL_PERCENT_CONSEC_READ > TOTAL_PERCENT_SEQ_READ ? \
                       TOTAL_PERCENT_CONSEC_READ : TOTAL_PERCENT_SEQ_READ ))
   TOTAL_PERCENT_RANDOM_READ=$(bc <<< "100.0 - $MAX_CONSEC_READ") 
   MAX_CONSEC_WRITE=$((TOTAL_PERCENT_CONSEC_WRITE > TOTAL_PERCENT_SEQ_WRITE ? \
                       TOTAL_PERCENT_CONSEC_WRITE : TOTAL_PERCENT_SEQ_WRITE ))
   TOTAL_PERCENT_RANDOM_WRITE=$(bc <<< "100.0 - $MAX_CONSEC_WRITE") 
}

function calc_percent_write_read_meta() {
   TOTAL_PERCENT_WRITE=$(bc <<< "($TOTAL_WTIME_WRITE * 100.0) / $TOTAL_IO_WTIME") 
   TOTAL_PERCENT_READ=$(bc <<< "($TOTAL_WTIME_READ * 100.0) / $TOTAL_IO_WTIME") 
   TOTAL_PERCENT_META=$(bc <<< "100.0 - ($TOTAL_PERCENT_WRITE + $TOTAL_PERCENT_READ)") 
}

function output_report() {
   cat <<EOF >${DARSHAN_IO_PROFILE_NAME}.json
{
"total_number_files": $TOTAL_NUMBER_FILES,
"io_time": {
            "percentage_of_total_wtime": $TOTAL_PERCENT_IO_WTIME,
            "percentage_write": $TOTAL_PERCENT_WRITE,
            "percentage_read": $TOTAL_PERCENT_READ,
            "percentage_meta": $TOTAL_PERCENT_META
          },
"throughput_MiBps": {
                     "posix": $TOTAL_POSIX_MiBps,
                     "stdio": $TOTAL_STDIO_MiBps, 
                     "write": $TOTAL_TRANSFER_RATE_MiBps_WRITE,
                     "read": $TOTAL_TRANSFER_RATE_MiBps_READ
                   },
"IOPS": {
           "total": $TOTAL_IOPTS,
           "percentage": {
                          "write": $TOTAL_PERCENT_IOPTS_WRITE,
                          "read": $TOTAL_PERCENT_IOPTS_READ
                         }
        },
"data_transferred": {
                      "total_bytes_transferred_MiB": $TOTAL_BYTES_TRANSFERRED_MiB,
                      "percentage": {
                                      "write": $TOTAL_PERCENT_TRANSFERRED_WRITE,
                                      "read": $TOTAL_PERCENT_TRANSFERRED_READ
                                    }
                    },
"transfersize_percentage": {
                             "write": {
                                        "0_100": $TOTAL_PERCENT_POSIX_SIZE_WRITE_0_100,
                                        "100_1K": $TOTAL_PERCENT_POSIX_SIZE_WRITE_100_1K,
                                        "1K_10K": $TOTAL_PERCENT_POSIX_SIZE_WRITE_1K_10K,
                                        "10K_100K": $TOTAL_PERCENT_POSIX_SIZE_WRITE_10K_100K,
                                        "100K_1M": $TOTAL_PERCENT_POSIX_SIZE_WRITE_100K_1M,
                                        "1M_4M": $TOTAL_PERCENT_POSIX_SIZE_WRITE_1M_4M,
                                        "4M_10M": $TOTAL_PERCENT_POSIX_SIZE_WRITE_4M_10M,
                                        "10M_100M": $TOTAL_PERCENT_POSIX_SIZE_WRITE_10M_100M,
                                        "100M_1G": $TOTAL_PERCENT_POSIX_SIZE_WRITE_100M_1G,
                                        "1G_PLUS": $TOTAL_PERCENT_POSIX_SIZE_WRITE_1G_PLUS
                                      },
                             "read": {
                                        "0_100": $TOTAL_PERCENT_POSIX_SIZE_READ_0_100,
                                        "100_1K": $TOTAL_PERCENT_POSIX_SIZE_READ_100_1K,
                                        "1K_10K": $TOTAL_PERCENT_POSIX_SIZE_READ_1K_10K,
                                        "10K_100K": $TOTAL_PERCENT_POSIX_SIZE_READ_10K_100K,
                                        "100K_1M": $TOTAL_PERCENT_POSIX_SIZE_READ_100K_1M,
                                        "1M_4M": $TOTAL_PERCENT_POSIX_SIZE_READ_1M_4M,
                                        "4M_10M": $TOTAL_PERCENT_POSIX_SIZE_READ_4M_10M,
                                        "10M_100M": $TOTAL_PERCENT_POSIX_SIZE_READ_10M_100M,
                                        "100M_1G": $TOTAL_PERCENT_POSIX_SIZE_READ_100M_1G,
                                        "1G_PLUS": $TOTAL_PERCENT_POSIX_SIZE_READ_1G_PLUS
                                     }
                           },
"io_pattern_percentage": {
                           "write" : {
                                       "sequential": $TOTAL_PERCENT_SEQ_WRITE,
                                       "random": $TOTAL_PERCENT_RANDOM_WRITE
                                     },
                           "read" : {
                                       "sequential": $TOTAL_PERCENT_SEQ_READ,
                                       "random": $TOTAL_PERCENT_RANDOM_READ
                                    },
                           "consecutive_write": $TOTAL_PERCENT_CONSEC_WRITE,
                           "consecutive_read": $TOTAL_PERCENT_CONSEC_READ
                         }
}
EOF
}

function format_json() {
   cat ${DARSHAN_IO_PROFILE_NAME}.json | jq . >& tmp.json && mv tmp.json ${DARSHAN_IO_PROFILE_NAME}.json
}

get_total_wtime /tmp/darshan_parser_total.out_$$

for PARAM in $POSIX_VALUES_TO_EXTRACT $STDIO_VALUES_TO_EXTRACT
do
   get_total /tmp/darshan_parser_total.out_$$ $PARAM
done

calc_total_transferred_read_write
calc_total_bytes_transferred
calc_percent_transferred_read_write
calc_percent_transfersize_read_write
calc_total_wtime_read_write_meta 
calc_transfer_rate_read_write
calc_total_io_wtime
calc_total_percent_io_wtime
calc_percent_io_pattern
calc_percent_write_read_meta
calc_total_iopts_read_write
calc_total_iopts
calc_total_percent_iopts_read_write
calc_total_number_files /tmp/darshan_parser_file.out_$$
get_performance_posix_stdio /tmp/darshan_parser_perf.out_$$

output_report
format_json

rm /tmp/darshan_parser_total.out_$$
rm /tmp/darshan_parser_file.out_$$
rm /tmp/darshan_parser_perf.out_$$
