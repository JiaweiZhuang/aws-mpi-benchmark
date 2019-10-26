if [ "$1" ]; then
  LOG_DIR=$1
  mkdir -p $LOG_DIR
  echo ""
else
  echo 'Must specify output log directory'
  exit 1
fi


spack env activate mpich3
cd $(spack location -i osu-micro-benchmarks)/libexec/osu-micro-benchmarks/mpi/collective

# only test default setting
unset MPIR_CVAR_USE_BCAST
unset MPIR_CVAR_BCAST_INTER_ALGORITHM
unset MPIR_CVAR_BCAST_INTRA_ALGORITHM

mpirun ./osu_bcast > $LOG_DIR/bcast_default.log

spack env deactivate
