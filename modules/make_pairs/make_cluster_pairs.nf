process MAKE_CLUSTER_PAIRS {

    tag "$meta.id"

    conda "${NXF_HOME}/assets/dmalzl/spritecooler/conda/spritefridge.yml"

    input:
    tuple val(meta), path(alignments)
    val(minClusterSize)
    val(maxClusterSize)


    output:
    tuple val(meta), path("pairs/*pairs"),  emit: pairs
    tuple val(meta), path('pairs/*bed'),    emit: bed
    tuple val(meta), path("pairs/*stats*"), emit: stats

    shell:
    '''
    spritefridge pairs \
        -b !{alignments} \
        -o pairs/!{meta.id} \
        -cl !{minClusterSize} \
        -ch !{maxClusterSize} \
        --separator '['
    '''
}