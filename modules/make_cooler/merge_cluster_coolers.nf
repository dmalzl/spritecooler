process MERGE_CLUSTER_COOLERS {

    tag "$meta.id"

    conda "${workflow.projectDir}/conda/spritefridge.yml"

    input:
    tuple val(meta), path(coolers, name: 'coolers/*')
    val nchunks

    output:
    tuple val(meta), path("*.cool"),    emit: cool
    tuple val(meta), path("*.mcool"),   emit: mcool

    shell:
    '''
    spritefridge combine \
        -i coolers \
        -o !{meta.id}.cool \
        --nchunks !{nchunks} \
        --floatcounts

    clustermcool.py -i coolers -o !{meta.id}.cluster.mcool
    '''
}