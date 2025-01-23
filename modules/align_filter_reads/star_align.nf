process STAR_ALIGN {
    tag "$meta.id"

    conda "${workflow.projectDir}/conda/star.yml"

    input:
    tuple val(meta), path(reads, stageAs: "input*/*")
    path(index)

    output:
    tuple val(meta), path('*.out.bam'),         emit: bam 
    tuple val(meta), path('*Log.final.out'),    emit: log

    script:
    def read_files_command = reads.extension == 'gz' ? "--readFilesCommand zcat" : ''
    """
    STAR \\
        --genomeDir ${index} \\
        --readFilesIn ${reads} \\
        --runThreadN ${task.cpus} \\
        --outFileNamePrefix ${meta.id}. \\
        --outSAMtype BAM Unsorted \\
        ${read_files_command}
    """
}