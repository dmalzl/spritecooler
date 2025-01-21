process STAR_ALIGN {
    tag "$meta.id"

    conda "${workflow.projectDir}/star.yml"

    input:
    tuple val(meta), path(reads, stageAs: "input*/*")
    path(index)
    path(gtf)

    output:
    tuple val(meta), path('*.out.bam'),        emit: bam 
    tuple val(meta), path('*Log.final.out'),    emit: log_final
    tuple val(meta), path('*Log.out'),          emit: log_out
    tuple val(meta), path('*Log.progress.out'), emit: log_progress

    script:
    """
    STAR \\
        --genomeDir $index \\
        --readFilesIn ${reads} \\
        --runThreadN $task.cpus \\
        --outFileNamePrefix $prefix. \\
        $out_sam_type \\
        $ignore_gtf \\
        $attrRG \\
        $args
    """
}