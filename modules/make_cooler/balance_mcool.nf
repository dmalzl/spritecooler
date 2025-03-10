process BALANCE_MCOOL {

    tag "$meta.id"

    conda "${workflow.projectDir}/conda/spritefridge/environment.yml"
    container "dmalzl/spritefridge:1.4.0"

    input:
    tuple val(meta), path(mcool)

    output:
    tuple val(meta), path("*balance.mcool"), emit: mcool

    script:
    """
    spritefridge balance \\
        -m ${mcool} \\
        -p ${task.cpus} \\
        -o ${meta.id}.balance.mcool \\
        --overwrite
    """
}
