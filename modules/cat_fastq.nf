process CAT_FASTQ {
    
    tag "$meta.id"

    input:
    tuple val(meta), path(reads, name: "input*/*")

    output:
    tuple val(meta), path("*.fq.gz"), emit: reads

    script:
    def readList = reads.collect { it.toString() }
    def read1 = []
    def read2 = []
    readList.eachWithIndex{ v, ix -> ( ix & 1 ? read2 : read1 ) << v }

    """
    mkdir merged
    cat ${read1.join(' ')} > ${meta.id}_1.fq.gz
    cat ${read2.join(' ')} > ${meta.id}_2.fq.gz
    """
}
