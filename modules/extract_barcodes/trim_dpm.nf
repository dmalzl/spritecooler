process TRIM_DPM {

    tag "$meta.id"

    conda "${NXF_HOME}/assets/dmalzl/spritecooler/conda/cutadapt.yml"

    input:
    tuple val(meta), path(reads)
    path(dpmfasta)

    output:
    tuple val(meta), path("*dpmtrim.fq"),   emit: reads
    tuple val(meta), path("*report.txt"),   emit: reports

    shell:
    '''
    cutadapt \
        -a GATCGGAAGAG \
        -g file:!{dpmfasta} \
        -o !{meta.id}.dpmtrim.fq \
        -j !{task.cpus} \
        !{reads} \
    > !{meta.id}.report.txt
    '''
}