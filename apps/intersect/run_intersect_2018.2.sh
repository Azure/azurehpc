#!/bin/bash
set -o errexit
set -o pipefail

APP_NAME=intersect
APP_VERSION=2018.2
case=${case:-BO_192_192_28}
APP_INSTALL_DIR=${APP_INSTALL_DIR:-/apps}
DATA_INSTALL_DIR=${DATA_INSTALL_DIR:-/scratch}
ECLPATH=$APP_INSTALL_DIR/ecl
#NOTE!! this path will depend on the dataset tar structure. the tar we used had case files under data e.g. data/BO_192_192_28 
CASEPATH=${PBS_O_WORKDIR}/${case}
export MODULEPATH=${APP_INSTALL_DIR}/modulefiles:$MODULEPATH
module use $APP_INSTALL_DIR/modulefiles
module load intersect_${APP_VERSION}
source ${ECLPATH}/tools/linux_x86_64/intel/mpi/2018.1.163/intel64/bin/mpivars.sh

cores=`cat $PBS_NODEFILE | wc -l`

cd $PBS_O_WORKDIR
cp $DATA_INSTALL_DIR/${case}.tgz .
tar xvf ${case}.tgz
#
start_time=$SECONDS
eclrun ecl2ix $CASEPATH/${case}
end_time=$SECONDS
ecl2ix_time=$(($end_time - $start_time))

start_time=$SECONDS
eclrun --hostfile=$PBS_NODEFILE -c ilmpi --np=$cores ix $CASEPATH/${case}
end_time=$SECONDS
eclrun_time=$(($end_time - $start_time))

case_output=$CASEPATH/${case}.LOG

# extract telemetry
if [ -f "${case_output}" ]; then
    # SECTION Simulation complete. E 215s = 0h03m35s | C [198s,206s] | M [879.1M,1.2G,29.1G]
    section_line=$(grep "SECTION  Simulation complete" ${case_output})
    total_wall_time=$(echo $section_line | cut -d 's' -f1 | cut -d 'E' -f3)
    min_cpu_time=$(echo $section_line | cut -d '[' -f2 | cut -d 's' -f1)
    max_cpu_time=$(echo $section_line | cut -d ',' -f2 | cut -d 's' -f1)
    min_memory=$(echo $section_line | cut -d '[' -f3 | cut -d ',' -f1)
    max_memory=$(echo $section_line | cut -d ',' -f3)
    total_memory=$(echo $section_line | cut -d ',' -f4 | cut -d ']' -f1)

    mpi_line=$(grep -A20 "REPORT   Elapsed and parallel time breakdown, variation among processors:" ${case_output} | tail -n 1)
    mpi_min_pertime=$(echo $mpi_line | cut -d '|' -f5 | tr '\n' ' ' | sed 's/ *//g')
    mpi_max_pertime=$(echo $mpi_line | cut -d '|' -f9 | tr '\n' ' ' | sed 's/ *//g')

    cat <<EOF >$APP_NAME.json
    {
    "version": "${APP_VERSION}",
    "model": "$case",
    "total_wall_time": $total_wall_time,
    "min_cpu_time": $min_cpu_time,
    "max_cpu_time": $max_cpu_time,
    "ecl2ix_time": $ecl2ix_time,
    "eclrun_time": $eclrun_time,
    "download_time": $download_time,
    "min_memory": "$min_memory",
    "max_memory": "$max_memory",
    "total_memory": "$total_memory",
    "mpi_min_pertime": $mpi_min_pertime,
    "mpi_max_pertime": $mpi_max_pertime
    }
EOF
fi
