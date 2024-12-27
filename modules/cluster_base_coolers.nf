process CLUSTER_BASE_COOLER {

    tag "$meta.id"

    input:
    tuple val(meta), path(pairs)
    path chromsizes
    val resolution
    val genome

    output:
    tuple val(meta), path("*base.cool"), emit: cools

    shell:
    '''
    cooler cload pairs \
        --assembly !{genome} \
        -c1 2 -p1 3 -c2 4 -p2 5 \
        !{chromsizes}:!{resolution} \
        !{pairs} \
        coolers/!{meta.id}_base.cool
    '''
}