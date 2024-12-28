include { CLUSTER_BASE_COOLERS  } from '../modules/make_cooler/cluster_base_coolers.nf'
include { MERGE_CLUSTER_COOLERS } from '../modules/make_cooler/merge_cluster_coolers.nf'
include { ZOOMIFY_COOLER        } from '../modules/make_cooler/zoomify_cooler.nf'
include { ANNOTATE_CLUSTERS     } from '../modules/make_cooler/annotate_coolers.nf'
include { BALANCE_MCOOL         } from '../modules/make_cooler/balance_mcool.nf'

workflow MAKE_COOLER {

}