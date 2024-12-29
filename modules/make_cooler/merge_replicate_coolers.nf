process MERGE_REPLICATE_COOLERS {

    tag "$meta.id"

    conda "${NXF_HOME}/assets/dmalzl/spritecooler/conda/spritefridge.yml"

    input:
    tuple val(meta), path(coolers)

    output:
    tuple val(meta), path("*.cool"), emit: cool

    shell:
    '''
    cooler merge !{meta.id}.cool !{coolers}
    '''
}