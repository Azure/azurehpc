#!/bin/bash

user=cycleadmin
hostlist=/shared/home/${user}/healthchecks/hostlist
EXEPATH=/shared/home/${user}/healthchecks/nccl/run_nccl_all_reduce.slrm
OUTDIR=/shared/home/${user}/healthchecks/nccl/out

mapfile -t ahostlist < $hostlist
#
if [ ! -d $OUTDIR ]; then
   mkdir -p $OUTDIR
fi

last=$(tail -n1 $hostlist)
src=$(tail -n1 $hostlist)

for index in ${!ahostlist[@]}; do
    dst=${ahostlist[$index]}
    if [ $((index%2)) -eq 0 ] && [ $dst != $last ]; then
       echo "1 $src,$dst"
       jobid=$(sbatch -N 2 -w $src,$dst --output ${OUTDIR}/${src}_${dst}_%A.out $EXEPATH | cut -d " " -f 4)
       if [ ${ahostlist[$((index+1))]} != $last ]; then
          sbatch -N 2 -w $dst,${ahostlist[$((index+1))]} --output ${OUTDIR}/${src}_${dst}_%A.out -d afterany:$jobid $EXEPATH
      fi
    fi
    src=$dst
done
lastm1=$(tail -n2 $hostlist|head -n1)
src=$lastm1
dst=$last
sbatch -N 2 -w $src,$dst --output ${OUTDIR}/${src}_${dst}_%A.out -d singleton $EXEPATH
