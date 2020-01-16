#!/bin/bash

q=$1
queue=${q:-None}
OUTDIR=/data/osu_ring_bw_hpcx
rm -rf $OUTDIR
mkdir -p $OUTDIR

NODE_FILENAME=osu_nodes.txt
if [ "$queue" != "None" ]; then
    echo "Queue: $queue"
    pbsnodes -avS | tail -n +3 | grep free | grep $queue | awk '{print $5}' > $NODE_FILENAME
else
    echo "No queue specified"
    pbsnodes -avS | tail -n +3 | grep free | awk '{print $5}' > $NODE_FILENAME
fi

cat $NODE_FILENAME

src=$(tail -n1 $NODE_FILENAME)
for line in $(<$NODE_FILENAME); do
    dst=$line
    echo "$src $dst"
    if [ "$src" = "$dst" ]
    then
        echo "$src ===== $dst"
        continue
    else
        if [ "$queue" != "None" ]; then
            qsub -q $queue -N osu_bw_test -v OUTDIR=$OUTDIR -l select=1:ncpus=1:host=$src+1:ncpus=1:host=$dst -l place=excl ~/apps/health_checks/run_ring_osu_bw_hpcx.pbs
        else
            qsub -N osu_bw_test -v OUTDIR=$OUTDIR -l select=1:ncpus=1:host=$src+1:ncpus=1:host=$dst -l place=excl ~/apps/health_checks/run_ring_osu_bw_hpcx.pbs
        fi
        src=$dst
        sleep .5
    fi
done

# wait until all JOBS are finished then run the report
JOBS=`qstat | grep osu_bw_test | wc -l`
echo -n "Remaining Jobs: $JOBS"
while [ $JOBS -ne "0" ]
do
    sleep 3
    JOBS=`qstat | grep osu_bw_test | wc -l`
    echo -n -e "\rRemaining Jobs: $JOBS   "
done

echo ""

first_ip=$(head -1 $NODE_FILENAME)
pattern=${first_ip:0:2}
cd $OUTDIR
grep -T "^8 " ${pattern}*latency* | sort -n -k 2 > osu_latency_report_$$.log
grep -T 4194304 ${pattern}*bw* | sort -n -k 2 > osu_bw_report_$$.log
grep -T 524288 ${pattern}*allreduce* | sort -n -k 2 > osu_allreduce_report_$$.log

sort -k3 -n $OUTDIR/osu_bw_report_$$.log > bw_report.out
sort -k3 -n $OUTDIR/osu_latency_report_$$.log > latency_report.out
sort -k3 -n $OUTDIR/osu_allreduce_report_$$.log > allreduce_report.out

cat bw_report.out | head -n100
cat latency_report.out | tail -n100
cat allreduce_report.out | tail -n100
