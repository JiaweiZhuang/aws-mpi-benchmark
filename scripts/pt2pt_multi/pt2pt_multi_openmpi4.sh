if [ "$1" ]; then
  LOG_DIR=$1
else
  echo 'Must specify output log directory'
  exit 1
fi

mkdir -p $LOG_DIR

if [ -z $OMPI_EFA ]; then
  spack env activate openmpi4
else
  spack env activate openmpi4-efa
fi

cd $(spack location -i osu-micro-benchmarks)/libexec/osu-micro-benchmarks/mpi/pt2pt

orterun ./osu_mbw_mr > $LOG_DIR/mbw_mr.log

spack env deactivate
