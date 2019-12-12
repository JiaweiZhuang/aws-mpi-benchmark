#!/bin/bash
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=36
#SBATCH --time=2:00:00

TOP_LOG_DIR=$HOME/osu_log/pt2pt_multi/
REPEAT=10

echo "Top-level output dir: $TOP_LOG_DIR"

for i in $(seq 1 $REPEAT); do
    echo "run $i of $REPEAT"

    SUB_LOG_DIR=$TOP_LOG_DIR/run${i}/

    ./pt2pt_multi_openmpi3.sh $SUB_LOG_DIR/openmpi3
    OMPI_EFA=1 ./pt2pt_openmpi3.sh $SUB_LOG_DIR/openmpi3-efa
    ./pt2pt_multi_openmpi4.sh $SUB_LOG_DIR/openmpi4
    OMPI_EFA=1 ./pt2pt_openmpi4.sh $SUB_LOG_DIR/openmpi4-efa

    export FI_PROVIDER=sockets
    ./pt2pt_multi_intelmpi.sh $SUB_LOG_DIR/intelmpi-tcp

    # the EFA case will fail if EFA is not available on the cluster
    export FI_PROVIDER=efa
    ./pt2pt_multi_intelmpi.sh $SUB_LOG_DIR/intelmpi-efa

done
