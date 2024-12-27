process BOWTIE2_ALIGN {

    tag "$meta.id"

    conda "bioconda::bowtie2=2.5.4 bioconda::samtools=1.21"

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
