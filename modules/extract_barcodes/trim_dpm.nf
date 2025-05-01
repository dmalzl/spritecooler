process TRIM_DPM {

    tag "$meta.id"

    conda "${workflow.projectDir}/conda/cutadapt.yml"
    container "quay.io/biocontainers/cutadapt:5.0--py311haab0aaa_0"

    input:
    tuple val(meta), path(reads)
    path(dpmfasta)

    output:
    tuple val(meta), path("*dpmtrim.fq"),   emit: reads
    tuple val(meta), path("*report.txt"),   emit: reports

    script:
    """
    cutadapt \\
        -a GATCGGAAGAG \\
        -a ATCAGCACTTA \\
        -g file:${dpmfasta} \\
        -o ${meta.id}.dpmtrim.fq \\
        -j ${task.cpus} \\
        --minimum-length 20 \\
        ${reads} \\
    > ${meta.id}.report.txt
    """
}