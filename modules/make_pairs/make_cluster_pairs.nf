process MAKE_CLUSTER_PAIRS {

    tag "$meta.id"

    conda "${workflow.projectDir}/conda/spritefridge.yml"

    input:
    tuple val(meta), path(alignments)
    val(minClusterSize)
    val(maxClusterSize)
    path(mqc_size_header)
    path(mqc_dedup_header)


    output:
    tuple val(meta), path("pairs/*pairs"),      emit: pairs
    tuple val(meta), path('pairs/*bed'),        emit: bed
    tuple val(meta), path("*aggsize.mqc.tsv"),  emit: size
    tuple val(meta), path("*dupstats.mqc.tsv"), emit: duplicate

    shell:
    '''
    mkdir pairs
    spritefridge pairs \
        -b !{alignments} \
        -o pairs/!{meta.id} \
        -cl !{minClusterSize} \
        -ch !{maxClusterSize} \
        --separator '['

    aggregate_size_stats.py -i pairs/!{meta.id}.sizestats.tsv -o !{meta.id}.aggsize.tsv

    cat !{mqc_size_header} !{meta.id}.aggsize.tsv > !{meta.id}.aggsize.mqc.tsv
    cat !{mqc_dedup_header} pairs/!{meta.id}.duplicatestats.tsv > !{meta.id}.dupstats.mqc.tsv
    '''
}