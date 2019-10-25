if [ "$1" ]; then
  LOG_DIR=$1
  echo ""
else
  echo 'Must specify output log directory'
  exit 1
fi

mkdir -p $LOG_DIR

spack env activate mpich3
cd $(spack location -i osu-micro-benchmarks)/libexec/osu-micro-benchmarks/mpi/collective

# only test default setting
unset MPIR_CVAR_USE_ALLREDUCE
unset MPIR_CVAR_ALLREDUCE_INTRA_ALGORITHM
unset MPIR_CVAR_ALLREDUCE_INTER_ALGORITHM

mpirun ./osu_allreduce > $LOG_DIR/allreduce_default.log

spack env deactivate
