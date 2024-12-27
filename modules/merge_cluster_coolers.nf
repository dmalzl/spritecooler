process MERGE_CLUSTER_COOLERS {

    tag "$meta.id"

    conda "conda/spritefridge.yml"

    input:
    tuple val(meta), path(coolers)
    val nchunks

    output:
    tuple val(meta), path("*.cool"), emit: cool

    shell:
    '''
    spritefridge combine \
        -i !{coolers} \
        -o !{meta.id}.cool \
        --nchunks !{nchunks} \
        --floatcounts
    '''
}