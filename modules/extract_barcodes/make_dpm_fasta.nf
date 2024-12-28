process MAKE_DPM_FASTA {

    tag "make_dpm_fasta"

    conda "${NXF_HOME}/assets/dmalzl/spritecooler/conda/spritefridge.yml"

    input:
    file(barcodes)

    output:
    path("dpm.fasta"), emit: fasta

    shell:
    '''
    make_dpm_fasta.py -i !{barcodes} -o dpm.fasta
    '''
}