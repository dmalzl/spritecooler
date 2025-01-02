process ZOOMIFY_COOLER {

    tag "$meta.id"

    conda "${workflow.projectDir}/conda/spritefridge.yml"

    input:
    tuple val(meta), path(cooler)
    val(resolutions)

    output:
    tuple val(meta), path("*.mcool"), emit: mcool

    shell:
    '''
    cooler zoomify \
        -p !{task.cpus} \
        -r !{resolutions} \
        -o !{meta.id}.mcool \
        !{cooler}
    '''

}