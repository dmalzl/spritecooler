process ZOOMIFY_COOLER {

    tag "$meta.id"

    input:
    tuple val(meta), path(cooler), val(resolutions)

    output:
    tuple val(meta), path("*.cool"), emit: cool

    shell:
    '''
    cooler zoomify \
        -p !{task.cpus} \
        -r !{resolutions} \
        -o !{meta.id}.mcool
    '''

}