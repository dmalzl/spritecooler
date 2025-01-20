include { MAKE_CLUSTER_PAIRS } from '../modules/make_pairs/make_cluster_pairs.nf'
include { SORT_BED           } from '../modules/make_pairs/sort_bed.nf'
include { MAKE_PAIRIX        } from '../modules/make_pairs/make_pairix.nf'

def log_failed(meta) {
    log.warn "number of pairsfiles for ${meta.id} below 5% of expected. Excluding from further processing"
}

workflow MAKE_PAIRS {
    take:
    ch_filtered_bam
    chromSizes
    minClusterSize
    maxClusterSize
    mqc_size_header
    mqc_dedup_header

    main:
    MAKE_CLUSTER_PAIRS (
        ch_filtered_bam,
        minClusterSize,
        maxClusterSize,
        mqc_size_header,
        mqc_dedup_header
    )

    // when number of valid reads (i.e. with full complement of barcodes) is low
    // pipeline tends to crash due to some weird behaviour of file emission
    // we filter anything that has a very low number of pairs files 
    def n_clusters_expected = maxClusterSize - minClusterSize
    MAKE_CLUSTER_PAIRS.out.pairs
        .map {
            meta, pairs ->
            [ meta, pairs.size() / n_clusters_expected * 100 > 5 ]
        }
        .set { ch_npairs_filter }

    MAKE_CLUSTER_PAIRS.out.pairs
        .join( ch_npairs_filter )
        .branch {
            meta, pairs, pass ->
                passed: pass
                    return [ meta, pairs ]

                failed: !pass
                    return [ meta, pairs ]
        }
        .set { ch_pairs }

    ch_pairs.failed
        .map { 
            meta, pairs -> 
            log_failed(meta)
        }

    // use join to only keep beds of passed samples
    ch_pairs.passed
        .map { it -> it[0] }
        .join( MAKE_CLUSTER_PAIRS.out.bed, remainder: false )
        .set { ch_bed_passed }
    
    ch_pairs.passed
        .flatMap { SpriteCooler.makeChunks( it, 50 ) }
        .set { ch_chunked_pairs }

    SORT_BED ( ch_bed_passed )

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
    pairs       = MAKE_PAIRIX.out.pairs
    bed         = SORT_BED.out.bed.mix ( ch_sample_pairs_bed )
    sizestats   = MAKE_CLUSTER_PAIRS.out.size
    dupstats    = MAKE_CLUSTER_PAIRS.out.duplicate
}