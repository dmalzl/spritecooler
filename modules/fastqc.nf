process FASTQC {

    tag "$meta.id"

    conda "bioconda::fastqc=0.12.1"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.html"), emit: html
    tuple val(meta), path("*.zip") , emit: zip

    shell:
    '''
    fastqc \
        --threads !{task.cpus} \
        !{reads}
    '''
}