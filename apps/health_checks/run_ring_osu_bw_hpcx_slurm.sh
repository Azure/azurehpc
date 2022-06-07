#!/bin/bash

q=$1
d=$2
queue=${q:-None}
OUTDIR=${d:-/shared/data/osu_ring_bw_hpcx}
rm -rf $OUTDIR
mkdir -p $OUTDIR
export OUTDIR=$OUTDIR

dir=$(pwd)

NODE_FILENAME=osu_nodes.txt
rm -rf $NODE_FILENAME
touch $NODE_FILENAME
nodelist=$(sinfo -N | grep idle | grep -v "idle~" | grep -v htc | awk '{print $1}' | sort -u)
echo $nodelist
IFS=' '
read -a nodearray <<< "$nodelist"
for node in ${nodelist[@]}
do
  echo $node >> $NODE_FILENAME
done

echo "-----------------------"
cat $NODE_FILENAME
echo "-----------------------"

src=$(tail -n1 $NODE_FILENAME)
while IFS= read -r line
do
    dst=$line
    if [ "$src" = "$dst" ]
    then
        echo "$src ===== $dst"
        continue
    else
        sbatch --nodelist=$src,$dst --time=00:03:00 --nodes=2 --ntasks=2 --ntasks-per-node=1 --job-name=osu_bw_test --output=$OUTDIR/osu_bw_test-%j.out --exclusive run_ring_osu_bw_hpcx.slurm
        src=$dst
        sleep .5
    fi
done < "$NODE_FILENAME"

# wait until all JOBS are finished then run the report
JOBS=`squeue -h -t pending | grep osu_bw_t | wc -l`
echo -n "Remaining Jobs: $JOBS"
while [ $JOBS -ne "0" ]
do
    sleep 3
    JOBS=`squeue -h | grep osu_bw_t | wc -l`
    echo -n -e "\rRemaining Jobs: $JOBS   "
done

echo ""

first_ip=$(head -1 $NODE_FILENAME)
pattern=${first_ip:0:2}
cd $OUTDIR

grep -T 4194304 ${pattern}*_bw.log | sort -n -k 2 > osu_bw_report_$$.log
grep -T 4194304 ${pattern}*_bibw.log | sort -n -k 2 > osu_bibw_report_$$.log
grep -T "^8 " ${pattern}*_latency.log | sort -n -k 2 > osu_latency_report_$$.log

sort -k3 -n $OUTDIR/osu_bw_report_$$.log > bw_report.out
sort -k3 -n $OUTDIR/osu_bibw_report_$$.log > bibw_report.out
sort -k3 -n $OUTDIR/osu_latency_report_$$.log > latency_report.out

echo "---------------"
cat bw_report.out | head -n100
echo "---------------"
cat bibw_report.out | head -n100
echo "---------------"
cat latency_report.out | tail -n100
echo "---------------"

grep -i error osu_bw_test*.out | tee osu_error_report.log
