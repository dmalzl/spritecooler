process SPLIT_RPM_DPM {

    tag "$meta.id"

    conda "${workflow.projectDir}/conda/spritefridge.yml"

    input:
    tuple val(meta), path(reads)
    val(keepSplitTag)
    path(mqc_header)

    output:
    tuple val(meta), path('*dpm.fq.gz'),    emit: dpm
    tuple val(meta), path('*rpm.fq.gz'),    emit: rpm
    tuple val(meta), path('*mqc.tsv'),      emit: stats

    script:
    def remove_dpm_tag = keepSplitTag ? '\\' : "| sed -e '/^@/ s/DPM[^|]*|//g' -e '/^@/ s/|DPM[^|]*\$//g' \\"
    def remove_rpm_tag = keepSplitTag ? '\\' : "| sed -e '/^@/ s/RPM[^|]*|//g' -e '/^@/ s/|RPM[^|]*\$//g' \\"
    """
    zgrep -A 3 DPM ${reads} \\
    | grep -v -- "^--\$" \\
    ${remove_dpm_tag}
    | gzip > ${meta.id}_dpm.fq.gz &

    zgrep -A 3 RPM ${reads} \\
    | grep -v -- "^--\$" \\
    ${remove_rpm_tag}
    | gzip > ${meta.id}_rpm.fq.gz

    wait

    dpms=\$(zcat ${meta.id}_dpm.fq.gz | wc -l)
    rpms=\$(zcat ${meta.id}_rpm.fq.gz | wc -l)
    echo "DPM\t"\$((\$dpms / 4)) > ${meta.id}_dpm.tsv &
    echo "RPM\t"\$((\$rpms / 4)) > ${meta.id}_rpm.tsv

    wait    # wait for jobs to finish

    cat ${mqc_header} ${meta.id}_dpm.tsv ${meta.id}_rpm.tsv > ${meta.id}_dpmrpmstats_mqc.tsv
    """

}