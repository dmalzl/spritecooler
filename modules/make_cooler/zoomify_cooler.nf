process ZOOMIFY_COOLER {

    tag "$meta.id"

    conda "${workflow.projectDir}/conda/spritefridge/environment.yml"
    container "docker.io/dmalzl/spritefridge:1.4.0"

    input:
    tuple val(meta), path(cooler)
    val(resolutions)

    output:
    tuple val(meta), path("*.mcool"), emit: mcool

    script:
    """
    cooler zoomify \\
        -p ${task.cpus} \\
        -r ${resolutions} \\
        -o ${meta.id}.mcool \\
        ${cooler}
    """
}