process MAKE_CLUSTER_PAIRS {

    tag "$meta.id"

    conda "bioconda::bowtie2=2.5.4"

    input:
    tuple val(meta), path(alignments)
    path index

    output:
    tuple val(meta), path("pairs"), emit: pairs

    shell:
    '''
    spritefridge pairs \
        -b !{alignments} \
        -o pairs/!{meta.id} \
        --separator '['
    '''
}