process FILTER_ALIGNMENTS {

    tag "$meta.id"

    conda "${workflow.projectDir}/conda/spritefridge.yml"

    input:
    tuple val(meta), path(bam)
    val(minq)

    output:
    tuple val(meta), path("*filtered.bam"), emit: bam
    tuple val(meta), path("*stats.tsv"),    emit: stats

    shell:
    '''
    filter_alignments.py \
        -i !{bam} \
        -q !{minq} \
        -o !{meta.id}
    '''

}