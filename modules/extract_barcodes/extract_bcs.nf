process EXTRACT_BCS {

    tag "$meta.id"

    conda "${workflow.projectDir}/conda/spritefridge.yml"

    input:
    tuple val(meta), path(reads)
    path(barcodes)
    val(layout1)
    val(layout2)
    val(mismatch)
    path(mqc_overall_header)
    path(mqc_poswise_header)

    output:
    tuple val(meta), path("*bcextract.fq.gz"),          emit: reads
    tuple val(meta), path("*_mqc.tsv"),                 emit: stats
    tuple val(meta), path("*valid_invalid_count.tsv"),  emit: summary

    script:
    def r1layout = layout1 ? "-l1 ${layout1}" : ""
    def r2layout = layout2 ? "-l2 ${layout2}" : ""
    """
    spritefridge extractbc \\
        -r1 ${reads[0]} \\
        -r2 ${reads[1]} \\
        -bc ${barcodes} \\
        ${r1layout} \\
        ${r2layout} \\
        -m "${mismatch}" \\
        -o ${meta.id}.bcextract.fq.gz \\
        -p ${task.cpus}

    # remove aggregate stats for multiqc
    tail -n +3 ${meta.id}.bcextract.overall.stats.tsv > tmp.stats.tsv
    cat ${mqc_overall_header} tmp.stats.tsv > ${meta.id}_overall_extractstats_mqc.tsv
    cat ${mqc_poswise_header} ${meta.id}.bcextract.poswise.stats.tsv > ${meta.id}_poswise_extractstats_mqc.tsv
    head -n 2 ${meta.id}.bcextract.overall.stats.tsv > ${meta.id}_valid_invalid_count.tsv
    """
}