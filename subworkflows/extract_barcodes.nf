include { EXTRACT_BCS        } from '../modules/extract_bcs.nf'
include { MAKE_DPM_FASTA     } from '../modules/make_dpm_fasta.nf'
include { TRIM_DPM           } from '../modules/trim_dpm.nf'

workflow EXTRACT_BARCODES {
    take:
    ch_trim_fastq
    barcodes
    r1layout
    r2layout
    mismatch

    main:
    EXTRACT_BCS ( 
        ch_trim_fastq,
        barcodes,
        r1Layout,
        r2Layout,
        mismatch
    )

    MAKE_DPM_FASTA ( barcodes )

    TRIM_DPM ( 
        EXTRACT_BCS.out.reads,
        ch_dpm_fasta
    )

    emit:
    reads = TRIM_DPM.out.reads
}