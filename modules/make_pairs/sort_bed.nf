process SORT_BED {

    tag "$meta.id"

    container "docker.io/centos:centos7"

    input:
    tuple val(meta), path(bed)

    output:
    tuple val(meta), path('*sort.bed'), emit: bed

    script:
    """
    sort -k1,1 -k2,2n ${bed} > ${meta.id}.sort.bed
    """
}