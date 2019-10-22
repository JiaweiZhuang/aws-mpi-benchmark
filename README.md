# MPI Benchmark on AWS HPC cluster

Benchmark various MPI functions on AWS HPC cluster. Including different EC2 instance types, network configurations, MPI implementations, and collective algorithms (e.g broadcast, allreduce).

The main motivation for such benchmark is that, different MPI implementations and their collective algorithms can yield vastly different efficiency and severely affect application performance. See those issues for example:

Most scripts in this repo also work on local HPC clusters with minimum modifications.

## Currently tested cases

MPI functions from [OSU micro-benchmarks (OMB)](http://mvapich.cse.ohio-state.edu/benchmarks/):
- Point-point: latency, bw, bibw, bw_mbr
- Collective: bcast, allreduce

AWS instance & network configuration:
- c5n.18xlarge + EFA (Intel-MPI only)
- c5n.18xlarge + TCP
- c5.18xlarge + TCP

MPI:
- Intel-MPI 2019.4 (come with pcluster 2.4.1)
- OpenMPI 3.1.4
- OpenMPI 4.0.0
- MPICH 3.3

## Browse benchmark results

See notebooks:

Take-away: Intel-MPI's topology-aware Bcast is 2~5x faster than other MPI implementations.

## Run the benchmarks

### Step 1. Launch cluster

Follow my [cloud HPC guide](https://jiaweizhuang.github.io/blog/aws-hpc-guide/) to get familiar with [AWS ParallelCluster](https://github.com/aws/aws-parallelcluster). Current benchmark uses this specific version with [EFA enabled](https://aws.amazon.com/hpc/efa/):

    pip install --upgrade aws-parallelcluster==2.4.1

Important parameters in `~/.parallelcluster/config` are:

    enable_efa = compute
    placement_group = DYNAMIC
    scheduler = slurm
    base_os = centos7
    master_instance_type = c5n.large
    compute_instance_type = c5n.18xlarge

Other parameters like key names, VPC and subnet IDs are user-specific.

### Step 2. Install MPI libraries and build OMB

For most MPIs except Intel-MPI, we use [Spack environment](https://spack.readthedocs.io/en/latest/environments.html#activating-environment-views) to simplify the installation and environment management. `spack env activate` discovers the MPI executable path, [functionally similar](https://spack.readthedocs.io/en/latest/environments.html#activating-environment-views) to `module load`.

Get Spack:

    cd $HOME
    git clone https://github.com/spack/spack.git
    echo 'source $HOME/spack/share/spack/setup-env.sh' >> $HOME/.bashrc
    source $HOME/.bashrc

Following sections install the environments `openmpi3`, `openmpi4`, `mpich3`. They will be shown in `spack env list`.

**Add pre-installed Slurm to Spack** by copying [spack_config/packages.yaml](./spack_config/packages.yaml) to `~/.spack/packages.yaml`

#### OpenMPI

    spack env create openmpi3
    spack env activate openmpi3
    spack -v install osu-micro-benchmarks ^openmpi@3.1.4+pmi schedulers=slurm
    spack env deactivate

    spack env create openmpi4
    spack env activate openmpi4
    spack -v install osu-micro-benchmarks ^openmpi@4.0.1+pmi schedulers=slurm
    spack env deactivate

The above installation uses TCP sockets. Libfabric & EFA can be enabled via `spack install openmpi+pmi schedulers=slurm fabrics=libfabric ^libfabric fabrics=efa`, but OpenMPI + EFA is currently quite slow for collectives due to [this issue](https://github.com/aws/aws-parallelcluster/issues/1143).

#### MPICH

    spack env create mpich3
    spack env activate mpich3
    spack -v install osu-micro-benchmarks ^mpich@3.3.1 +slurm
    spack env deactivate

#### Intel MPI

We the pre-installed Intel-MPI on AWS ParallelCluster, to avoid the hassle of [configuring Intel-MPI with libfabric and EFA](https://docs.aws.amazon.com/en_us/AWSEC2/latest/UserGuide/efa-start.html#efa-start-impi).

    module avail
    module show intelmpi

    module purge
    module load intelmpi
    which mpicc mpirun

Switching fabric by one of the following:

    export FI_PROVIDER=efa  # default if EFA is available
    export FI_PROVIDER=sockets  # fall back to TCP instead

Print which fabric is used at run-time:

    export I_MPI_DEBUG=5

Install OMB from source:

    cd $HOME
    wget http://mvapich.cse.ohio-state.edu/download/mvapich/osu-micro-benchmarks-5.6.1.tar.gz
    tar zxf osu-micro-benchmarks-5.6.1.tar.gz
    rm osu-micro-benchmarks-5.6.1.tar.gz
    cd osu-micro-benchmarks-5.6.1

    echo 'export OSU_PATH_INTELMPI=$HOME/osu_intelmpi' >> $HOME/.bashrc
    source $HOME/.bashrc

    module purge && module load intelmpi
    ./configure CC=mpicc CXX=mpicxx --prefix=$OSU_PATH_INTELMPI
    make
    make install

The variable `OSU_PATH_INTELMPI` will be used in run-time scripts.

#### Note on MPI process management and scheduler

In general, MPI collectives place one MPI process one physical core. Each c5n.18xlarge instance has 36 physical cores / 72 hyperthreads. Slurm thinks there 72 cores so will by default. Here we use `--ntasks-per-node 36` for `srun` command and `sbatch` script to avoid oversubscribe the CPUs. A better way will be [disabling hyperthreading](https://aws.amazon.com/blogs/compute/disabling-intel-hyper-threading-technology-on-amazon-linux/).

MPI processes can be launched by MPI library's launcher or by Slurm, leading to various different ways to start the program.

Open MPI:
1. Launch by `srun`. OpenMPI needs to be compiled with `--with-pmi` (already handled by Spack).
2. Launch by `orterun` inside slurm interactive session or sbatch script. Still need to compile with `--with-slurm`.

Intel MPI :
1. Launch by `srun`. Need to set `export I_MPI_PMI_LIBRARY=/opt/slurm/lib/libpmi.so`
2. Launch by `mpirun` inside slurm interactive session or sbatch script. Should `unset I_MPI_PMI_LIBRARY`

Ref:
- https://slurm.schedmd.com/mpi_guide.html
- https://www.open-mpi.org/faq/?category=slurm
- https://software.intel.com/en-us/mpi-developer-guide-linux-job-schedulers-support

### Step 3. Running OSU micro-benchmark (OMB)

See [scripts](./scripts) directory. The scripts assume that MPI & OMB are properly installed as shown in Step 2.

Run all the cases via Slurm `sbatch`. For example:

    cd scripts/bcast/
    sbatch run_bcast_all_mpi.sbatch

Or run each case interactively:

    srun -N 4 --ntasks-per-node 36 --pty bash
    bash bcast_openmpi3_tune_algo.sh ~/output_log_dir

Feel free to change `--nodes` and `--ntasks-per-node` in the Slurm script.

### Tips on OMB run-time configuration

See [OMB README](http://mvapich.cse.ohio-state.edu/static/media/mvapich/README-OMB.txt) for full documentation.

- Performance variation: A single execution like `mpirun ./osu_bcast` already averages over 1000 calls for small messages and 100 calls for large messages, as shown by `osu_bcast -f` (can reduce the iteration number by `-i 10`). However, such averaged number might still have significant variations due to network instabilities, system interrupts, etc. TCP/socket generally has larger variations than EFA. Thus it is recommended to rerun each benchmark several times and look at the mean or medium value.

- MPI message size: All OSU benchmarks uses 4 Bytes ~ 1 MB (2^20 = 1048576 Bytes) by default, and I simply use such default size for all benchmarks. Can change the message size by something like `osu_bcast -m 4:8192` if needed.

### Tune MPI collectives

#### Tune IntelMPI collectives

Uses `I_MPI_ADJUST` family, such as `I_MPI_ADJUST_BCAST`:

    1. Binomial
    2. Recursive doubling
    3. Ring
    4. Topology aware binomial
    5. Topology aware recursive doubling
    6. Topology aware ring
    7. Shumilin's
    8. Knomial
    9. Topology aware SHM-based flat
    10. Topology aware SHM-based Knomial
    11. Topology aware SHM-based Knary
    12. NUMA aware SHM-based (SSE4.2)
    13. NUMA aware SHM-based (AVX2)
    14. NUMA aware SHM-based (AVX512)

For example, set `export I_MPI_ADJUST_BCAST=8`.

Ref:
- https://software.intel.com/en-us/mpi-developer-reference-windows-i-mpi-adjust-family-environment-variable
- https://software.intel.com/en-us/articles/tuning-the-intel-mpi-library-basic-techniques

#### Tune OpenMPI collectives

Print all algorithms by:

    ompi_info --param coll tuned -l 9 | grep 'bcast algorithm'

OpenMPI 3.1.4:

    0 ignore, 1 basic linear, 2 chain, 3: pipeline, 4: split binary tree, 5: binary tree, 6: binomial tree.

OpenMPI 4.0.1:

    0 ignore, 1 basic linear, 2 chain, 3: pipeline, 4: split binary tree, 5: binary tree, 6: binomial tree, 7: knomial tree, 8: scatter_allgather, 9: scatter_allgather_ring.

Then specify the algorithm by command line arguments:

    orterun --mca coll_tuned_use_dynamic_rules 1 --mca coll_tuned_bcast_algorithm 7

Or by environment variables (useful when using `srun` instead of `orterun`):

    export OMPI_MCA_coll_tuned_use_dynamic_rules=1
    export OMPI_MCA_coll_tuned_bcast_algorithm=7

Ref:
- https://www.open-mpi.org/faq/?category=tuning#setting-mca-params
- https://stackoverflow.com/a/36639939
- https://medium.com/@esaliya/choosing-a-specific-collective-algorithm-implementation-in-openmpi-d96ccc8aa9e7

#### Tune MPICH collectives

Can set environment variables like `MPIR_CVAR_BCAST_INTRA_ALGORITHM`. Not seeing a major effect here.

Ref:
- https://wiki.mpich.org/mpich/index.php/Collectives_framework
- https://github.com/pmodels/mpich/blob/master/src/mpi/coll/bcast/bcast.c

## References

- [Performance Analysis of MPI Collective Operations](http://www.netlib.org/utk/people/JackDongarra/PAPERS/coll-perf-analysis-cluster-2005.pdf)
- [Everything You Need to Know About the Intel MPI Library](https://www.intel.com/content/dam/www/public/us/en/documents/presentation/things-mpi-library.pdf)
- [Optimization of Collective Communication Operations in MPICH](https://www.mcs.anl.gov/~thakur/papers/ijhpca-coll.pdf)
