process MERGE_REPLICATE_COOLERS {

    tag "$meta.id"

    conda "${workflow.projectDir}/conda/spritefridge/environment.yml"
    container "docker.io/dmalzl/spritefridge:1.4.2"

    input:
    tuple val(meta), path(coolers, name: 'coolers/*')

    output:
    tuple val(meta), path("*.cool"), emit: cool

    script:
    """
    cooler merge ${meta.id}.cool ${coolers}
    """
}