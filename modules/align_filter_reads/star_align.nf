process STAR_ALIGN {
    tag "$meta.id"

    conda "${workflow.projectDir}/star.yml"

    input:
    tuple val(meta), path(reads, stageAs: "input*/*")
    path(index)

    output:
    tuple val(meta), path('*.out.bam'),         emit: bam 
    tuple val(meta), path('*Log.final.out'),    emit: log

    script:
    """
    STAR \\
        --genomeDir ${index} \\
        --readFilesIn ${reads} \\
        --runThreadN ${task.cpus} \\
        --outFileNamePrefix ${meta.id}. \\
        --outSAMtype BAM Unsorted
    """
}