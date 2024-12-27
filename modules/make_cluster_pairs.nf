process MAKE_CLUSTER_PAIRS {

    tag "$meta.id"

    conda "${NXF_HOME}/assets/dmalzl/spritecooler/conda/spritefridge.yml"

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