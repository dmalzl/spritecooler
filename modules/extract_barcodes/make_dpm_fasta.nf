process MAKE_DPM_FASTA {

    tag "make_dpm_fasta"

    conda "${workflow.projectDir}/conda/spritefridge.yml"

    input:
    file(barcodes)

    output:
    path("dpm.fasta"), emit: fasta

    script:
    """
    make_dpm_fasta.py -i ${barcodes} -o dpm.fasta
    """
}
