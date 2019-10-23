if [ "$1" ]; then
  LOG_DIR=$1
else
  echo 'Must specify output log directory'
  exit 1
fi

mkdir -p $LOG_DIR

spack env activate mpich3
cd $(spack location -i osu-micro-benchmarks)/libexec/osu-micro-benchmarks/mpi/pt2pt

mpirun ./osu_latency > $LOG_DIR/latency.log
mpirun ./osu_bw > $LOG_DIR/bw.log
mpirun ./osu_bibw > $LOG_DIR/bibw.log

spack env deactivate
