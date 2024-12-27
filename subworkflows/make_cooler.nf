include { CLUSTER_BASE_COOLERS  } from '../modules/cluster_base_coolers.nf'
include { MERGE_CLUSTER_COOLERS } from '../modules/merge_cluster_coolers.nf'
include { ZOOMIFY_COOLER        } from '../modules/zoomify_cooler.nf'
include { ANNOTATE_CLUSTERS     } from '../modules/annotate_coolers.nf'
include { MAKE_MCOOL            } from '../modules/make_mcool.nf'
include { BALANCE_MCOOL         } from '../modules/balance_mcool.nf'

workflow MAKE_COOLER {

}