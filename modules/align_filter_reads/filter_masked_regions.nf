process FILTER_ALIGNMENTS {

    tag "$meta.id"

    conda "${workflow.projectDir}/conda/spritefridge.yml"

    input:
    tuple val(meta), path(bam)
    path(genome_mask)
    path(mqc_header)

    output:
    tuple val(meta), path("*masked.bam"),           emit: bam
    tuple val(meta), path("*maskstats_mqc.tsv"),    emit: stats

    script:
    """
    bedtools intersect -v \\
        -a ${bam} \\
        -b ${genome_mask} \\
        > ${meta.id}.masked.bam

    compute_mask_stats.py \\
        -i ${bam} \\
        -m ${meta.id}.masked.bam \\
        -o ${meta.id}.stats.tsv

    cat ${mqc_header} ${meta.id}.stats.tsv > ${meta.id}_maskstats_mqc.tsv
    """
}