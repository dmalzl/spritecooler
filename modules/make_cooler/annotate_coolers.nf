process ANNOTATE_COOLERS {

    tag "$meta.id"

    conda "${NXF_HOME}/assets/dmalzl/spritecooler/conda/spritefridge.yml"

    input:
    tuple val(meta), path(mcool)
    tuple val(meta2), path(bed)

    output:
    tuple val(meta), path("*.mcool"), emit: cool
    
    shell:
    '''
    spritefridge annotate \
        -i !{mool} \
        -b !{bed}
    '''
}