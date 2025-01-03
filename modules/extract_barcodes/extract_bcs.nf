process EXTRACT_BCS {

    tag "$meta.id"

    conda "${workflow.projectDir}/conda/spritefridge.yml"

    input:
    tuple val(meta), path(reads)
    path(barcodes)
    val(layout1)
    val(layout2)
    val(mismatch)
    path(mqc_header)

    output:
    tuple val(meta), path("*bcextract.fq.gz"), emit: reads
    tuple val(meta), path("*_mqc.tsv"),   emit: stats

    shell:
    '''
    spritefridge extractbc \
        -r1 !{reads[0]} \
        -r2 !{reads[1]} \
        -bc !{barcodes} \
        -l1 "!{layout1}" \
        -l2 "!{layout2}" \
        -m "!{mismatch}" \
        -o !{meta.id}.bcextract.fq.gz \
        -p !{task.cpus}

    # remove aggregate stats for multiqc
    tail -n +3 !{meta.id}.bcextract.stats.tsv > tmp.stats.tsv
    cat !{mqc_header} tmp.stats.tsv > !{meta.id}_extractstats_mqc.tsv
    '''
}