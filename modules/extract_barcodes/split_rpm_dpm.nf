process SPLIT_RPM_DPM {

    tag "$meta.id"

    conda "${workflow.projectDir}/conda/spritefridge.yml"

    input:
    tuple val(meta), path(reads)
    path(mqc_header)

    output:
    tuple val(meta), path('*dpm.fq.gz'),    emit: dpm
    tuple val(meta), path('*rpm.fq.gz'),    emit: rpm
    tuple val(meta), path('*mqc.tsv'),      emit: stats

    script:
    """
    zgrep -A 3 DPM ${reads} \\
    | grep -v -- "^--$" \\
    | sed -e '/^@/ s/DPM[^|]*|//g' \\
    | gzip > ${meta.id}_dpm.fq.gz &

    zgrep -A 3 RPM ${reads} \\
    | grep -v -- "^--$" \\
    | sed -e '/^@/ s/RPM[^|]*|//g' \\
    | gzip > ${meta.id}_rpm.fq.gz

    echo "DPM\t"$(gzcat ${meta.id}_dpm.fq.gz | wc -l) > ${meta.id}_dpm.tsv &
    echo "RPM\t"$(gzcat ${meta.id}_rpm.fq.gz | wc -l) > ${meta.id}_rpm.tsv

    wait    # wait for jobs to finish

    cat ${mqc_header} ${meta.id}_dna.tsv ${meta.id}_rpm.tsv > ${meta.id}_dpmrpmstats_mqc.tsv
    """

}