process TRIM_DPM {

    tag "$meta.id"

    input:
    tuple val(meta), path(reads)
    path(dpmfasta)

    output:
    tuple val(meta), path("*bcextract.fq.gz"), emit: reads
    path "*stats.tsv",                         emit: reports // needs to be fixed for cutadapt output

    shell:
    '''
    cutadapt \
        -a GATCGGAAGAG \
        -g file:!{dpmfasta} \
        -o trimmed/!{meta.id}.dpm.fq \
        -j !{task.cpus} \
        !{reads}
    '''
}