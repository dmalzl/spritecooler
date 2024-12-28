process BOWTIE2_ALIGN {

    tag "$meta.id"

    conda "${NXF_HOME}/assets/dmalzl/spritecooler/conda/align.yml"

    input:
    tuple val(meta), path(reads)
    path(index)

    output:
    tuple val(meta), path("*bam"), emit: bam

    shell:
    '''
    bowtie2 \
        -p !{task.cpus} \
        --phred33 \
        -x !{index} \
        -U !{reads} \
    | samtools view -b > !{meta.id}.bam
    '''

}