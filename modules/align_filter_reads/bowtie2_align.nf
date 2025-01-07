process BOWTIE2_ALIGN {

    tag "$meta.id"

    conda "${NXF_HOME}/assets/dmalzl/spritecooler/conda/align.yml"

    input:
    tuple val(meta), path(reads)
    path(index)

    output:
    tuple val(meta), path('*bam'),          emit: bam
    tuple val(meta), path('*bowtie2.log'),  emit: log

    script:
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
    2> ${meta.id}.tmp.log \\
    | samtools view -b > ${meta.id}.bam

    cat ${meta.id}.tmp.log | grep -v Warning > ${meta.id}.bowtie2.log
    """
}
