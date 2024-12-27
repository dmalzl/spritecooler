process MAKE_DPM_FASTA {

    tag "make_dpm_fasta"

    input:
    path barcodes

    output:
    path "*fasta", emit: fasta

    shell:
    '''
    make_dpm_fasta.py -i !{barcodes} -o dpm.fasta
    '''
}