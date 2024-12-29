process TRIM_DPM {

    tag "$meta.id"

    conda "${NXF_HOME}/assets/dmalzl/spritecooler/conda/cutadapt.yml"

    input:
    tuple val(meta), path(reads)
    path(dpmfasta)

    output:
    tuple val(meta), path("*dpmtrim.fq"),       emit: reads
    // path "*stats.tsv",                      emit: stats

    shell:
    '''
    cutadapt \
        -a GATCGGAAGAG \
        -g file:!{dpmfasta} \
        -o !{meta.id}.dpmtrim.fq \
        -j !{task.cpus} \
        !{reads}
    '''
}