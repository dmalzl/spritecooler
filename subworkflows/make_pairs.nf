include { MAKE_CLUSTER_PAIRS } from '../modules/make_pairs/make_cluster_pairs.nf'
include { MAKE_PAIRIX        } from '../modules/make_pairs/make_pairix.nf'

workflow MAKE_PAIRS {
    take:
    ch_filtered_bam
    chromSizes
    minClusterSize
    maxClusterSize

    main:
    MAKE_CLUSTER_PAIRS (
        ch_filtered_bam,
        minClusterSize,
        maxClusterSize
    )

    MAKE_CLUSTER_PAIRS.out.pairs
        .flatMap { SpriteCooler.makeChunks( it, 50 ) }
        .set { ch_chunked_pairs }

    MAKE_PAIRIX (
        ch_chunked_pairs,
        chromSizes
    )

    emit:
    pairs = MAKE_PAIRIX.out.pairs
    stats = MAKE_CLUSTER_PAIRS.out.stats
}