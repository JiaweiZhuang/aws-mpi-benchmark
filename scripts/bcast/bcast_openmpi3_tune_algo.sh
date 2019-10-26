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
  algos=$(seq 0 6)
elif [ $MPI_ALGO == 'quick' ]; then
  algos='4'  # split binary tree
elif [ $MPI_ALGO == 'default' ]; then
  algos=''
else
  echo 'Invalid $MPI_ALGO'
  exit 1
fi


spack env activate openmpi3
cd $(spack location -i osu-micro-benchmarks)/libexec/osu-micro-benchmarks/mpi/collective

orterun ./osu_bcast > $LOG_DIR/bcast_default.log

for algo in $algo; do
    orterun \
    --mca coll_tuned_use_dynamic_rules 1 \
    --mca coll_tuned_bcast_algorithm $algo \
    ./osu_bcast > $LOG_DIR/bcast_algo$algo.log
done

spack env deactivate
