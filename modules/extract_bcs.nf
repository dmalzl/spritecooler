process EXTRACT_BCS {

    tag "$meta.id"

    conda "conda/spritefridge.yml"

    input:
    tuple val(meta), path(reads)
    path(barcodes)
    val(layout1)
    val(layout2)
    val(mismatch)

    output:
    tuple val(meta), path("*bcextract.fq.gz"), emit: reads
    tuple val(meta), path("*stats.tsv"),       emit: stats

    shell:
    '''
    spritefridge extractbc \
        -r1 !{reads[0]} \
        -r2 !{reads[1]} \
        -bc !{barcodes} \
        -l1 !{layout1} \
        -l2 !{layout2} \
        -m !{mismatch} \
        -o !{meta.id}.bcextract.fq.gz \
        -p !{task.cpus}
    '''
}