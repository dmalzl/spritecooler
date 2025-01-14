include { EXTRACT_BCS        } from '../modules/extract_barcodes/extract_bcs.nf'
include { MAKE_DPM_FASTA     } from '../modules/extract_barcodes/make_dpm_fasta.nf'
include { TRIM_DPM           } from '../modules/extract_barcodes/trim_dpm.nf'
include { FASTQC             } from '../modules/fastqc.nf'

workflow EXTRACT_BARCODES {
    take:
    ch_trim_fastq
    barcodes
    r1layout
    r2layout
    mismatch
    mqc_header

    main:
    EXTRACT_BCS ( 
        ch_trim_fastq,
        barcodes,
        r1layout,
        r2layout,
        mismatch,
        mqc_header
    )

    MAKE_DPM_FASTA ( barcodes )

    TRIM_DPM ( 
        EXTRACT_BCS.out.reads,
        MAKE_DPM_FASTA.out.fasta
    )

    FASTQC ( TRIM_DPM.out.reads )

    emit:
    reads   = TRIM_DPM.out.reads
    extract = EXTRACT_BCS.out.stats
    trim    = TRIM_DPM.out.reports
    html    = FASTQC.out.html
    zip     = FASTQC.out.zip
}