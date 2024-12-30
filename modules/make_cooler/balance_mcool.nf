process BALANCE_MCOOL {

    tag "$meta.id"

    conda "${NXF_HOME}/assets/dmalzl/spritecooler/conda/spritefridge.yml"

    input:
    tuple val(meta), path(mcool)

    output:
    tuple val(meta), path("*mcool"), emit: mcool

    script:
    """
    spritefridge balance \
        -m !{mcool} \
        -p !{task.cpus} \
        --overwrite
    """
}
