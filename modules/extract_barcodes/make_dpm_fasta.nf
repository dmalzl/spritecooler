process MAKE_DPM_FASTA {

    tag "make_dpm_fasta"

    conda "${workflow.projectDir}/conda/spritefridge.yml"

    input:
    file(barcodes)
    val(dpm)

    output:
    path("dpm.fasta"), emit: fasta

    script:
    """
    make_dpm_fasta.py \\
        -i ${barcodes} \\
        --dpm ${dpm} \\
        -o dpm.fasta
    """
}
