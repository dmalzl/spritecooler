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
        extension = '.gz' ? reads[0].extension == 'gz' : ''
        """
        [ ! -f  ${meta.id}_1.fq${extension} ] && ln -s ${reads[0]} ${meta.id}_1.fq${extension}
        [ ! -f  ${meta.id}_2.fq${extension} ] && ln -s ${reads[1]} ${meta.id}_2.fq${extension}
        fastqc \\
            --threads ${task.cpus} \\
            ${meta.id}_1.fq${extension} \\
            ${meta.id}_2.fq${extension}
        """
    } else {
        extension = '.gz' ? reads.extension == 'gz' : ''
        """
        [ ! -f  ${meta.id}.fq${extension} ] && ln -s ${reads} ${meta.id}.fq${extension}
        fastqc \\
            --threads ${task.cpus} \\
            ${meta.id}.fq${extension}
        """
    }

}