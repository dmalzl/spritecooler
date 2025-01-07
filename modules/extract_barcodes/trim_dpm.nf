process TRIM_DPM {

    tag "$meta.id"

    conda "${workflow.projectDir}/conda/cutadapt.yml"

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
        -g file:${dpmfasta} \\
        -o ${meta.id}.dpmtrim.fq \\
        -j ${task.cpus} \\
        --minimum-length 20 \\
        ${reads} \\
    > ${meta.id}.report.txt
    """
}