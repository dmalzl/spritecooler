process ANNOTATE_COOLERS {

    tag "$meta.id"

    conda "${NXF_HOME}/assets/dmalzl/spritecooler/conda/spritefridge.yml"

    input:
    tuple val(meta), path(coolers)
    path clusterbed

    output:
    tuple val(meta), path("*.cool"), emit: cool
    
    shell:
    '''
    spritefridge annotate \
        -i !{coolers} \
        -b !{clusterbed}
    '''
}