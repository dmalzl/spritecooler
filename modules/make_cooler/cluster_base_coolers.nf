process CLUSTER_BASE_COOLERS {

    tag "$meta.id"

    conda "${NXF_HOME}/assets/dmalzl/spritecooler/conda/spritefridge.yml"

    input:
    tuple val(meta), path(pairs, name: 'pairs/*')
    path chromsizes
    val resolution
    val genome

    output:
    tuple val(meta), path("coolers/*.cool"), emit: cools

    shell:
    '''
    mkdir coolers
    for pairs in `ls *pairs.blksrt.gz`;
    do
        pairsbase=$(basename ${pairs%.pairs.blksrt.gz})
        cooler cload pairs \
            --assembly !{genome} \
            -c1 2 -p1 3 -c2 4 -p2 5 \
            !{chromsizes}:!{resolution} \
            ${pairs} \
            coolers/${pairsbase}_base.cool
    done
    '''
}