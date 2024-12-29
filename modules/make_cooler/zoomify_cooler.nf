process ZOOMIFY_COOLER {

    tag "$meta.id"

    conda "${NXF_HOME}/assets/dmalzl/spritecooler/conda/spritefridge.yml"

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
        -o !{meta.id}.mcool
    '''

}