
bcast_algo_intelmpi = [
    '1. Binomial',
    '2. Recursive doubling',
    '3. Ring',
    '4. Topology aware binomial',
    '5. Topology aware recursive doubling',
    '6. Topology aware ring',
    "7. Shumilin's",
    '8. Knomial',
    '9. Topology aware SHM-based flat',
    '10. Topology aware SHM-based Knomial',
    '11. Topology aware SHM-based Knary',
    '12. NUMA aware SHM-based (SSE4.2)',
    '13. NUMA aware SHM-based (AVX2)',
    '14. NUMA aware SHM-based (AVX512)'
]

bcast_algo_openmpi3 = [
    '0. ignore',
    '1. basic linear',
    '2. chain',
    '3. pipeline',
    '4. split binary tree',
    '5. binary tree',
    '6. binomial tree'
]

bcast_algo_openmpi4 = [
    '0. ignore',
    '1. basic linear',
    '2. chain',
    '3. pipeline',
    '4. split binary tree',
    '5. binary tree',
    '6. binomial tree',
    '7. knomial tree',
    '8. scatter_allgather',
    '9. scatter_allgather_ring'
]
