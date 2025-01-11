process ANNOTATE_COOLERS {

    tag "$meta.id"

    conda "${workflow.projectDir}/conda/spritefridge.yml"

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