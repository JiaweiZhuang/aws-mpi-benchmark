if [ "$1" ]; then
  LOG_DIR=$1
  mkdir -p $LOG_DIR
else
  echo 'Must specify output log directory'
  exit 1
fi

if [ -z $OSU_PATH_INTELMPI ]; then
  echo 'Must specify $OSU_PATH_INTELMPI'
  exit 1
fi

if [ -z $MPI_ALGO ]; then
  MPI_ALGO='full'
fi

if [ $MPI_ALGO == 'full' ]; then
  algos=$(seq 1 12)
elif [ $MPI_ALGO == 'default' ]; then
  algos=''
else
  echo 'Invalid $MPI_ALGO'
  exit 1
fi


module purge
module load intelmpi
unset I_MPI_PMI_LIBRARY

cd $OSU_PATH_INTELMPI/libexec/osu-micro-benchmarks/mpi/collective

unset I_MPI_ADJUST_ALLREDUCE
mpirun ./osu_allreduce > $LOG_DIR/allreduce_default.log

for algo in $algos; do
    export I_MPI_ADJUST_ALLREDUCE=$algo
    mpirun ./osu_allreduce > $LOG_DIR/allreduce_algo${algo}.log
done

module purge
