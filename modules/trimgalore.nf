process TRIMGALORE {

    tag "$meta.id"

    conda "${workflow.projectDir}/conda/trimgalore.yml"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*_trimmed_val_*.fq.gz"), emit: reads
    tuple val(meta), path("*zip"),                  emit: zip
    tuple val(meta), path("*html"),                 emit: html
    tuple val(meta), path("*report.txt"),           emit: reports

    script:
    """
    # rename for multiqc
    [ ! -f  ${meta.id}_1.fq.gz ] && ln -s ${reads[0]} ${meta.id}_1.fq.gz
    [ ! -f  ${meta.id}_2.fq.gz ] && ln -s ${reads[1]} ${meta.id}_2.fq.gz
    trim_galore --paired \\
                --quality 20 \\
                --fastqc \\
                --gzip \\
                --output_dir . \\
                --basename ${meta.id}_trimmed \\
                --cores ${task.cpus} \\
                ${meta.id}_1.fq.gz \\
                ${meta.id}_2.fq.gz
    """
}
