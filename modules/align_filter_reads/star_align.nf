process STAR_ALIGN {
    tag "$meta.id"

    conda "${workflow.projectDir}/conda/star.yml"
    container 'nf-core/htslib_samtools_star_gawk:311d422a50e6d829'

    input:
    tuple val(meta), val(readtype), path(reads, stageAs: "input*/*")
    path(index)

    output:
    tuple val(meta), val(readtype), path('*.out.bam'),  emit: bam 
    tuple val(meta), path('*Log.final.out'),            emit: log

    script:
    def read_files_command = reads.extension == 'gz' ? "--readFilesCommand zcat" : ''
    def prefix = "${meta.id}_${readtype}"
    """
    STAR \\
        --genomeDir ${index} \\
        --readFilesIn ${reads} \\
        --runThreadN ${task.cpus} \\
        --outFileNamePrefix ${prefix}. \\
        --outSAMtype BAM Unsorted \\
        ${read_files_command}
    """
}