# Run fio benchmark
#
#$DIRECTORY="Z\:\numtargets_8"
$DIRECTORY="Z\:\."
$ALLJOBS = 1 2 4 8 16 32 64
#
$DIRECTORY2 = $DIRECTORY.replace("\:",":")
$BS_THROUGHPUT = "4M"
$BS_IOPS = "4K"
$SIZE_THROUGHPUT = "2G"
$SIZE_IOPS = "128M"
#
#
foreach ($NUMJOBS in $ALLJOBS)
{
Write-Host "NUMJOBS=$NUMJOBS"
#
# throughput BM (multiple jobs)
#
$NAME = "throughput"
$FULLPATH = $DIRECTORY2 + "\" + $NAME + "*"
$BS = $BS_THROUGHPUT
$SIZE = $SIZE_THROUGHPUT
$RW = "write"
$OUTPUT = "fio" + "_" + $RW + "_" + $NAME + "_" + $BS + "_" + $SIZE + "_" + $NUMJOBS + ".out"
fio --name=$NAME --rw=$RW --bs=$BS --size=$SIZE --direct=1 --directory=$DIRECTORY --numjobs=$NUMJOBS --group_reporting --output=$OUTPUT
rm $FULLPATH
Start-Sleep 2
$RW = "read"
$OUTPUT = "fio" + "_" + $RW + "_" + $NAME + "_" + $BS + "_" + $SIZE + "_" + $NUMJOBS + ".out"
fio --name=$NAME --rw=$RW --bs=$BS --size=$SIZE --direct=1 --directory=$DIRECTORY --numjobs=$NUMJOBS --group_reporting --output=$OUTPUT
rm $FULLPATH
Start-Sleep 2
#
# IOPS BM (multiple jobs)
#
$NAME = "iops"
$FULLPATH = $DIRECTORY2 + "\" + $NAME + "*"
$BS = $BS_IOPS
$SIZE = $SIZE_IOPS
$RW = "write"
$OUTPUT = "fio" + "_" + $RW + "_" + $NAME + "_" + $BS + "_" + $SIZE + "_" + $NUMJOBS + ".out"
fio --name=$NAME --rw=$RW --bs=$BS --size=$SIZE --direct=1 --directory=$DIRECTORY --numjobs=$NUMJOBS --group_reporting --output=$OUTPUT
rm $FULLPATH
Start-Sleep 2
$RW = "read"
$OUTPUT = "fio" + "_" + $RW + "_" + $NAME + "_" + $BS + "_" + $SIZE + "_" + $NUMJOBS + ".out"
fio --name=$NAME --rw=$RW --bs=$BS --size=$SIZE --direct=1 --directory=$DIRECTORY --numjobs=$NUMJOBS --group_reporting --output=$OUTPUT
rm $FULLPATH
}
