process BALANCE_MCOOL {

    tag "$meta.id"

    conda "${workflow.projectDir}/conda/spritefridge.yml"

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
