process ANNOTATE_COOLERS {

    tag "$meta.id"

    conda "${workflow.projectDir}/conda/spritefridge/environment.yml"
    container "docker.io/dmalzl/spritefridge:1.4.0"

    input:
    tuple val(meta), path(mcool), path(bed)

    output:
    tuple val(meta), path("*tsv.gz"), emit: annotations
    
    script:
    """
    spritefridge annotate \\
        -i ${mcool} \\
        -b ${bed} \\
        -o ${meta.id}
    """
}