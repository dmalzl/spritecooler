process FASTQC {

    tag "$meta.id"

    conda "bioconda::fastqc=0.12.1"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.html"), emit: html
    tuple val(meta), path("*.zip") , emit: zip

    script:
    def nfiles = reads.size()
    def paired = true ? nfiles > 1 : false
    if (paired) {
        """
        [ ! -f  ${meta.id}_1.fq.gz ] && ln -s ${reads[0]} ${meta.id}_1.fq.gz
        [ ! -f  ${meta.id}_2.fq.gz ] && ln -s ${reads[1]} ${meta.id}_2.fq.gz
        fastqc \\
            --threads ${task.cpus} \\
            ${meta.id}_1.fq.gz \\
            ${meta.id}_2.fq.gz
        """
    } else {
                """
        [ ! -f  ${meta.id}.fq.gz ] && ln -s ${reads} ${meta.id}.fq.gz
        fastqc \\
            --threads ${task.cpus} \\
            ${meta.id}.fq.gz
        """
    }

}