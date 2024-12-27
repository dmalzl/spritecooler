process MAKE_PAIRIX {

    tag "$meta.id"

    input:
    tuple val(meta), path(pairs)
    path chromsizes

    output:
    tuple val(meta), path('*pairs.blksrt.gz*'), emit: pairix

    shell:
    '''
    cooler csort \
        -c1 2 -c2 4 \
        -p1 3 -p2 5 \
        -p 4 \
        !{pairs} \
        !{chromsizes}
    '''

}