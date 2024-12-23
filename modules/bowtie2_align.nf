process {

    tag "$meta.id"

    input:
    tuple val(meta), path(reads)
    path index

    output:
    tuple val(meta), path("*sam"), emit: alignments

    shell:
    '''
    bowtie2 \
        -p !{task.cpus} \
        --phred33 \
        -x !{index} \
        -U !{reads}
    '''

}
