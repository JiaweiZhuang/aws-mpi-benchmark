#!/bin/bash
#SBATCH --nodes=4
#SBATCH --ntasks-per-node=36
#SBATCH --time=2:00:00

N=$SLURM_JOB_NUM_NODES
n=$SLURM_NTASKS
echo "Using $N nodes, $n cores"

TOP_LOG_DIR=$HOME/osu_log/bcast/N${N}n${n}/
REPEAT=5

echo "Top-level output dir: $TOP_LOG_DIR"

for i in $(seq 1 $REPEAT); do
    echo "run $i of $REPEAT"

    SUB_LOG_DIR=$HOME/osu_log/bcast/N${N}n${n}/run${i}/

    bash ./bcast_openmpi3_tune_algo.sh $SUB_LOG_DIR/openmpi3
    bash ./bcast_openmpi4_tune_algo.sh  $SUB_LOG_DIR/openmpi4
    bash ./bcast_mpich3.sh  $SUB_LOG_DIR/mpich3

    export FI_PROVIDER=sockets
    bash ./bcast_intelmpi_tune_algo.sh $SUB_LOG_DIR/intelmpi-tcp

    # the EFA case will fail if EFA is not available on the cluster 
    export FI_PROVIDER=efa
    bash ./bcast_intelmpi_tune_algo.sh $SUB_LOG_DIR/intelmpi-efa

done
