#!/bin/bash
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=1
#SBATCH --time=2:00:00

TOP_LOG_DIR=$HOME/osu_log/pt2pt/
REPEAT=10

echo "Top-level output dir: $TOP_LOG_DIR"

for i in $(seq 1 $REPEAT); do
    echo "run $i of $REPEAT"

    SUB_LOG_DIR=$TOP_LOG_DIR/run${i}/

    bash ./pt2pt_openmpi3.sh $SUB_LOG_DIR/openmpi3
    bash ./pt2pt_openmpi4.sh $SUB_LOG_DIR/openmpi4

    export FI_PROVIDER=sockets
    bash ./pt2pt_intelmpi.sh $SUB_LOG_DIR/intelmpi-tcp

    # the EFA case will fail if EFA is not available on the cluster
    export FI_PROVIDER=efa
    bash ./pt2pt_intelmpi.sh $SUB_LOG_DIR/intelmpi-efa

done
