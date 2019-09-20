UTDIR=/data/osu_ring_bw_hpcx
rm -rf $OUTDIR
mkdir -p $OUTDIR

NODE_FILENAME=osu_nodes.txt
#pbsnodes -avS | tail -n +3 | head -n 5 | awk '{print $5}' > $NODE_FILENAME
pbsnodes -avS | tail -n +3 | awk '{print $5}' > $NODE_FILENAME


src=$(tail -n1 $NODE_FILENAME)
for line in $(<$NODE_FILENAME); do
    dst=$line
    qsub -N osu_bw_test -v OUTDIR=$OUTDIR -l select=1:ncpus=1:host=$src+1:ncpus=1:host=$dst -l place=excl run_ring_osu_bw_hpcx.pbs
    src=$dst
    sleep .5
done

# wait until all JOBS are finished then run the report
JOBS=`qstat | grep osu_bw_test | wc -l`
echo -n "Remaining Jobs: $JOBS"
while [ $JOBS -ne "0" ]
do
    sleep 3
    JOBS=`qstat | grep osu_bw_test | wc -l`
    echo -n -e "\rRemaining Jobs: $JOBS"
done

echo ""

first_ip=$(head -1 $NODE_FILENAME)
pattern=${first_ip:0:2}
cd $OUTDIR
grep -T "^8 " ${pattern}*latency* | sort -n -k 2 > osu_latency_report.log_$$
grep -T 4194304 ${pattern}*bw* | sort -n -k 2 > osu_bw_report.log_$$

sort -k3 -n $OUTDIR/osu_bw_report.log_* > bw_report.out
sort -k3 -n $OUTDIR/osu_latency_report.log_* > latency_report.out

cat bw_report.out
cat latency_report.out
