process FASTQC {

    tag "$meta.id"

    conda "bioconda::fastqc=0.12.1"
    container "biocontainers/fastqc:0.12.1--hdfd78af_0"

    input:
    tuple val(meta), val(suffix), path(reads)

    output:
    tuple val(meta), path("*.html"), emit: html
    tuple val(meta), path("*.zip") , emit: zip

    script:
    def nfiles = reads.size()
    def paired = nfiles > 1 ? true : false
    def prefix = suffix ? "${meta.id}_${suffix}" : "${meta.id}"
    if (paired) {
        extension = reads[0].extension == 'gz' ? '.gz' : ''
        """
        [ ! -f  ${prefix}_1.fq${extension} ] && ln -s ${reads[0]} ${prefix}_1.fq${extension}
        [ ! -f  ${prefix}_2.fq${extension} ] && ln -s ${reads[1]} ${prefix}_2.fq${extension}
        fastqc \\
            --threads ${task.cpus} \\
            ${prefix}_1.fq${extension} \\
            ${prefix}_2.fq${extension}
        """
    } else {
        extension = reads.extension == 'gz' ? 'gz' : ''
        """
        [ ! -f  ${prefix}.fq${extension} ] && ln -s ${reads} ${prefix}.fq${extension}
        fastqc \\
            --threads ${task.cpus} \\
            ${prefix}.fq${extension}
        """
    }

}