process FILTER_ALIGNMENTS {

    tag "$meta.id"

    conda "${workflow.projectDir}/conda/spritefridge.yml"

    input:
    tuple val(meta), path(bam)
    val(minq)
    path(mqc_header)

    output:
    tuple val(meta), path("*filtered.bam"), emit: bam
    tuple val(meta), path("*_mqc.tsv"),    emit: stats

    script:
    """
    filter_alignments.py \\
        -i ${bam} \\
        -q ${minq} \\
        -o ${meta.id}

    cat ${mqc_header} ${meta.id}.stats.tsv > ${meta.id}_filterstats_mqc.tsv
    """
}