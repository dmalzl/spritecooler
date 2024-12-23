process {

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