process FILTER_MASKED_REGIONS {

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
    def prefix = "${meta.id}_${meta.readtype}"
    """
    bedtools intersect -v \\
        -a ${bam} \\
        -b ${genome_mask} \\
        > ${prefix}.masked.bam

    compute_mask_stats.py \\
        -i ${bam} \\
        -m ${prefix}.masked.bam \\
        -o ${prefix}.stats.tsv

    cat ${mqc_header} ${prefix}.stats.tsv > ${prefix}_maskstats_mqc.tsv
    """
}