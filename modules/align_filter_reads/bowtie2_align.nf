process BOWTIE2_ALIGN {

    tag "$meta.id"

    conda "${workflow.projectDir}/conda/bowtie2/envrionment.yml"
    container "dmalzl/bowtie2:2.5.4"

    input:
    tuple val(meta), val(readtype), path(reads)
    path(index)

    output:
    tuple val(meta), val(readtype), path('*bam'),   emit: bam
    tuple val(meta), path('*bowtie2.log'),          emit: log

    script:
    def prefix = "${meta.id}_${readtype}"
    """
    # taken from cutandrun nf-core pipeline
    # basically finds the name of the index and exits if not found
    INDEX=`find -L ./ -name "*.rev.1.bt2" | sed "s/\\.rev.1.bt2\$//"`
    [ -z "\$INDEX" ] && INDEX=`find -L ./ -name "*.rev.1.bt2l" | sed "s/\\.rev.1.bt2l\$//"`
    [ -z "\$INDEX" ] && echo "Bowtie2 index files not found" 1>&2 && exit 1

    bowtie2 \\
        -p ${task.cpus} \\
        --phred33 \\
        -x \$INDEX \\
        -U ${reads} \\
    2> ${prefix}.tmp.log \\
    | samtools view -b > ${prefix}.bam

    cat ${prefix}.tmp.log | grep -v Warning > ${prefix}.bowtie2.log
    """
}
