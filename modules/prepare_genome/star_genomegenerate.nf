process STAR_GENOMEGENERATE {
    tag "$star_base"

    conda "${workflow.projectDir}/star.yml"

    input:
    path(genomeFasta)
    path(gtf)

    output:
    tuple val(star_base), path("star"), emit: index

    script:
    def memory = task.memory ? "--limitGenomeGenerateRAM ${task.memory.toBytes() - 100000000}" : ''
    def star_base = genomeFasta.getSimpleName()
    """
    samtools faidx $genomeFasta
    NUM_BASES=`gawk '{sum = sum + \$2}END{if ((log(sum)/log(2))/2 - 1 > 14) {printf "%.0f", 14} else {printf "%.0f", (log(sum)/log(2))/2 - 1}}' ${genomeFasta}.fai`

    mkdir star
    STAR \\
        --runMode genomeGenerate \\
        --genomeDir star/ \\
        --genomeFastaFiles $genomeFasta \\
        --sjdbGTFfile $gtf \\
        --runThreadN $task.cpus \\
        --genomeSAindexNbases \$NUM_BASES \\
        $memory
    """
}