process BALANCE_MCOOL {

    tag "$meta.id"

    input:
    tuple val(meta), file(mcool)

    output:
    tuple val(meta), file("${mcool}"), emit: matrix

    script:
    """
    mcoolbalance -m ${mcool} -p ${task.cpus}
    """
}
