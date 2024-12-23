process {

    tag "$meta.id"

    input:
    tuple val(meta), path(alignments)
    path index

    output:
    tuple val(meta), path("pairs"), emit: alignments

    shell:
    '''
    clusterpairs \
        -b !{alignments} \
        -o pairs/!{meta.id} \
        --separator '['
    '''
}