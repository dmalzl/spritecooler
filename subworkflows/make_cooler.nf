include { CLUSTER_BASE_COOLERS    } from '../modules/make_cooler/cluster_base_coolers.nf'
include { MERGE_CLUSTER_COOLERS   } from '../modules/make_cooler/merge_cluster_coolers.nf'
include { MERGE_REPLICATE_COOLERS } from '../modules/make_cooler/merge_replicate_coolers.nf'
include { ZOOMIFY_COOLER          } from '../modules/make_cooler/zoomify_cooler.nf'
include { PLOT_COOLER             } from '../modules/make_cooler/plot_cooler.nf'
include { ANNOTATE_COOLERS        } from '../modules/make_cooler/annotate_coolers.nf'
include { BALANCE_MCOOL           } from '../modules/make_cooler/balance_mcool.nf'

workflow MAKE_COOLER {
    take:
    ch_chunked_pairs
    ch_pairs_bed
    baseResolution
    resolutions
    chromSizes
    genomeName

    main:
    CLUSTER_BASE_COOLERS (
        ch_chunked_pairs,
        chromSizes,
        baseResolution,
        genomeName
    )

    CLUSTER_BASE_COOLERS.out.cools
        .groupTuple ( by: [0] )
        .map {
            meta, coolers ->
            [ meta, coolers.flatten() ]
        }
        .set { ch_base_coolers }

    MERGE_CLUSTER_COOLERS (
        ch_base_coolers
    )

    MERGE_CLUSTER_COOLERS.out.cool
        .map {
            meta, cool ->
            meta_new = [:]
            meta_new.id = meta.sample
            meta_new.sample = meta.sample
            [ meta_new, cool ]
        }
        .groupTuple ( by: [0] )
        .branch {
            meta, cools ->
                single  : cools.size() == 1
                    return [ meta, cools.flatten() ]
                multiple: cools.size() > 1
                    return [ meta, cools.flatten() ]
        }
        .set { ch_branched_cools }

    MERGE_REPLICATE_COOLERS ( ch_branched_cools.multiple )

    MERGE_REPLICATE_COOLERS.out.cool
        .mix ( MERGE_CLUSTER_COOLERS.out.cool, ch_branched_cools.single )
        .filter { meta, cool -> meta.id != meta.sample } // filter pseudo merged in case single replicate
        .set { ch_base_cool }

    ZOOMIFY_COOLER (
        ch_base_cool,
        resolutions
    )

    PLOT_COOLER ( ZOOMIFY_COOLER.out.mcool )

    BALANCE_MCOOL ( ZOOMIFY_COOLER.out.mcool )

    ZOOMIFY_COOLER.out.mcool
        .join ( ch_pairs_bed )
        .set { ch_mcool_bed }

    ANNOTATE_COOLERS ( ch_mcool_bed )
}