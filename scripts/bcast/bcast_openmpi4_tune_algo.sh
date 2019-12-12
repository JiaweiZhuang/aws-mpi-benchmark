if [ "$1" ]; then
  LOG_DIR=$1
  mkdir -p $LOG_DIR
else
  echo 'Must specify output log directory'
  exit 1
fi


if [ -z $MPI_ALGO ]; then
  MPI_ALGO='full'
fi

if [ $MPI_ALGO == 'full' ]; then
  algos=$(seq 0 9)
elif [ $MPI_ALGO == 'quick' ]; then
  algos='4 7'  # split binary tree, knomial tree
elif [ $MPI_ALGO == 'default' ]; then
  algos=''
else
  echo 'Invalid $MPI_ALGO'
  exit 1
fi

if [ -z $OMPI_EFA ]; then
  spack env activate openmpi4
else
  spack env activate openmpi4-efa
fi

cd $(spack location -i osu-micro-benchmarks)/libexec/osu-micro-benchmarks/mpi/collective

orterun ./osu_bcast > $LOG_DIR/bcast_default.log

for algo in $algos; do
    orterun \
    --mca coll_tuned_use_dynamic_rules 1 \
    --mca coll_tuned_bcast_algorithm $algo \
    ./osu_bcast > $LOG_DIR/bcast_algo$algo.log
done

spack env deactivate
