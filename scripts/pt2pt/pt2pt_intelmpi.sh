if [ "$1" ]; then
  LOG_DIR=$1
else
  echo 'Must specify output log directory'
  exit 1
fi

if [ -z $OSU_PATH_INTELMPI ]; then
  echo 'Must specify $OSU_PATH_INTELMPI'
  exit 1
fi

mkdir -p $LOG_DIR

module purge
module load intelmpi
unset I_MPI_PMI_LIBRARY

cd $OSU_PATH_INTELMPI/libexec/osu-micro-benchmarks/mpi/pt2pt

mpirun ./osu_latency > $LOG_DIR/latency.log
mpirun ./osu_bw > $LOG_DIR/bw.log
mpirun ./osu_bibw > $LOG_DIR/bibw.log

module purge
