process ANNOTATE_COOLERS {

    tag "$meta.id"

    conda "${NXF_HOME}/assets/dmalzl/spritecooler/conda/spritefridge.yml"

    input:
    tuple val(meta), path(mcool), path(bed)

    output:
    tuple val(meta), path("*annotated.mcool"), emit: mcool
    
    shell:
    '''
    spritefridge annotate \
        -i !{mcool} \
        -b !{bed}
    '''
}