process MAKE_PAIRIX {

    tag "$meta.id"

    conda "${NXF_HOME}/assets/dmalzl/spritecooler/conda/spritefridge.yml"

    input:
    tuple val(meta), path(pairs)
    path chromsizes

    output:
    tuple val(meta), path('*pairs.blksrt.gz*'), emit: pairs

    shell:
    '''
    for pairfile in `ls *pairs`;
    do
        cooler csort \
            -c1 2 -c2 4 \
            -p1 3 -p2 5 \
            -p !{task.cpus} \
            !{pairs} \
            !{chromsizes}
    done
    '''

}