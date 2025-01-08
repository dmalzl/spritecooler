process MERGE_CLUSTER_COOLERS {

    tag "$meta.id"

    conda "${workflow.projectDir}/conda/spritefridge.yml"

    input:
    tuple val(meta), path(coolers, name: 'coolers/*')
    val nchunks

    output:
    tuple val(meta), path("*.cool"),    emit: cool
    tuple val(meta), path("*.mcool"),   emit: mcool

    script:
    """
    spritefridge combine \\
        -i coolers \\
        -o ${meta.id}.cool

    cluster_mcool.py -i coolers -o ${meta.id}.cluster.mcool
    """
}