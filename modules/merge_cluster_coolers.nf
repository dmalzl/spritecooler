process {

    tag "$meta.id"

    input:
    tuple val(meta), path(coolers)
    val nchunks

    output:
    tuple val(meta), path("*.cool"), emit: cool

    shell:
    '''
    comotate \
        -i !{coolers} \
        -o !{meta.id}.cool \
        --nchunks !{nchunks} \
        --floatcounts
    '''
}