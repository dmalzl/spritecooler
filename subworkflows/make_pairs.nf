include { MAKE_CLUSTER_PAIRS } from '../modules/make_pairs/make_cluster_pairs.nf'
include { SORT_BED           } from '../modules/make_pairs/sort_bed.nf'
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

    SORT_BED ( MAKE_CLUSTER_PAIRS.out.bed )

    SORT_BED.out.bed
        .map {
            meta, bed ->
            meta_new = [:]
            meta_new.id = meta.sample
            [ meta_new, bed ]
        }
        .groupTuple ( by: [0] )
        .map {
            meta, beds ->
            [ meta, beds.flatten() ]
        }
        .set { ch_sample_pairs_bed }

    MAKE_PAIRIX (
        ch_chunked_pairs,
        chromSizes
    )

    emit:
    pairs   = MAKE_PAIRIX.out.pairs
    bed     = SORT_BED.out.bed.mix ( ch_sample_pairs_bed )
    stats   = MAKE_CLUSTER_PAIRS.out.stats
}