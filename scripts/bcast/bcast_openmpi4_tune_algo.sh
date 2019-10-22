if [ "$1" ]; then
  LOG_DIR=$1
else
  echo 'Must specify output log directory'
  exit 1
fi

mkdir -p $LOG_DIR

spack env activate openmpi4
cd $(spack location -i osu-micro-benchmarks)/libexec/osu-micro-benchmarks/mpi/collective

orterun ./osu_bcast > $LOG_DIR/bcast_default.log

for algo in {0..9}; do
    orterun \
    --mca coll_tuned_use_dynamic_rules 1 \
    --mca coll_tuned_bcast_algorithm $algo \
    ./osu_bcast > $LOG_DIR/bcast_algo$algo.log
done

spack env deactivate
