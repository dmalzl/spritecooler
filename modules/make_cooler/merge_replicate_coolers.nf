process MERGE_REPLICATE_COOLERS {

    tag "$meta.id"

    conda "${workflow.projectDir}/conda/spritefridge.yml"

    input:
    tuple val(meta), path(coolers, name: 'coolers/*')

    output:
    tuple val(meta), path("*.cool"), emit: cool

    script:
    """
    cooler merge ${meta.id}.cool ${coolers}
    """
}