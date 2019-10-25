if [ "$1" ]; then
  LOG_DIR=$1
else
  echo 'Must specify output log directory'
  exit 1
fi

mkdir -p $LOG_DIR

spack env activate openmpi3
cd $(spack location -i osu-micro-benchmarks)/libexec/osu-micro-benchmarks/mpi/collective

orterun ./osu_allreduce > $LOG_DIR/allreduce_default.log

for algo in {0..5}; do
    orterun \
    --mca coll_tuned_use_dynamic_rules 1 \
    --mca coll_tuned_allreduce_algorithm $algo \
    ./osu_allreduce > $LOG_DIR/allreduce_algo$algo.log
done

spack env deactivate
