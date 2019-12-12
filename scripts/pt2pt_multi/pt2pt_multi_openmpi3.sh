if [ "$1" ]; then
  LOG_DIR=$1
else
  echo 'Must specify output log directory'
  exit 1
fi

mkdir -p $LOG_DIR

spack env activate openmpi3
cd $(spack location -i osu-micro-benchmarks)/libexec/osu-micro-benchmarks/mpi/pt2pt

orterun ./osu_mbw_mr > $LOG_DIR/mbw_mr.log

spack env deactivate
