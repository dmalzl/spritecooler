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

    shell:
    '''
    trim_galore --paired \
                --quality 20 \
                --fastqc \
                --gzip \
                --output_dir . \
                --basename !{meta.id}_trimmed \
                --cores !{task.cpus} \
                !{reads}
    '''
}
