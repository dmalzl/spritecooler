process FILTER_ALIGNMENTS {

    tag "$meta.id"

    conda "${workflow.projectDir}/conda/spritefridge.yml"

    input:
    tuple val(meta), path(bam)
    val(minq)
    path(mqc_header)

    output:
    tuple val(meta), path("*filtered.bam"), emit: bam
    tuple val(meta), path("*_mqc.tsv"),     emit: stats

    script:
    def prefix = "${meta.id}_${meta.readtype}"
    """
    filter_alignments.py \\
        -i ${bam} \\
        -q ${minq} \\
        -o ${prefix}

    cat ${mqc_header} ${prefix}.stats.tsv > ${prefix}_filterstats_mqc.tsv
    """
}