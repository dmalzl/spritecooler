process FILTER_ALIGNMENTS {

    tag "$meta.id"

    conda "${workflow.projectDir}/conda/spritefridge.yml"

    input:
    tuple val(meta), val(readtype), path(bam)
    val(minq)
    path(mqc_header)

    output:
    tuple val(meta), val(readtype), path("*filtered.bam"), emit: bam
    tuple val(meta), path("*_mqc.tsv"),     emit: stats

    script:
    def prefix = "${meta.id}_${readtype}"
    """
    filter_alignments.py \\
        -i ${bam} \\
        -q ${minq} \\
        -o ${prefix}

    cat ${mqc_header} ${prefix}.stats.tsv > ${prefix}_filterstats_mqc.tsv
    """
}