process SORT_BED {

    tag "$meta.id"

    input:
    tuple val(meta), path(bed)

    output:
    tuple val(meta), path('*sort.bed'), emit: bed

    shell:
    '''
    sort -k1,1 -k2,2n !{bed} > !{meta.id}.sort.bed
    '''
}