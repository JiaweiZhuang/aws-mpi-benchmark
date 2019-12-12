#!/bin/bash
#SBATCH --nodes=8
#SBATCH --ntasks-per-node=36
#SBATCH --time=4:00:00

N=$SLURM_JOB_NUM_NODES
n=$SLURM_NTASKS
echo "Using $N nodes, $n cores"

TOP_LOG_DIR=$HOME/osu_log/allreduce/N${N}n${n}/
REPEAT=5
# export MPI_ALGO='default'
export MPI_ALGO='full'

echo "Top-level output dir: $TOP_LOG_DIR"

for i in $(seq 1 $REPEAT); do
    echo "run $i of $REPEAT"

    SUB_LOG_DIR=$TOP_LOG_DIR/run${i}/

    ./allreduce_openmpi3_tune_algo.sh $SUB_LOG_DIR/openmpi3
    OMPI_EFA=1 ./allreduce_openmpi3_tune_algo.sh $SUB_LOG_DIR/openmpi3-efa
    ./allreduce_openmpi4_tune_algo.sh  $SUB_LOG_DIR/openmpi4
    OMPI_EFA=1 ./allreduce_openmpi4_tune_algo.sh  $SUB_LOG_DIR/openmpi4-efa
    ./allreduce_mpich3.sh  $SUB_LOG_DIR/mpich3

    export FI_PROVIDER=sockets
    ./allreduce_intelmpi_tune_algo.sh $SUB_LOG_DIR/intelmpi-tcp

    # the EFA case will fail if EFA is not available on the cluster 
    export FI_PROVIDER=efa
    ./allreduce_intelmpi_tune_algo.sh $SUB_LOG_DIR/intelmpi-efa

done
