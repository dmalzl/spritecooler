include { EXTRACT_BCS               } from '../modules/extract_barcodes/extract_bcs.nf'
include { SPLIT_RPM_DPM             } from '../modules/extract_barcodes/split_rpm_dpm.nf'
include { MAKE_DPM_FASTA            } from '../modules/extract_barcodes/make_dpm_fasta.nf'
include { TRIM_DPM as TRIM_RPM_DPM  } from '../modules/extract_barcodes/trim_dpm.nf'
include { FASTQC                    } from '../modules/fastqc.nf'


workflow EXTRACT_BARCODES {
    take:
    ch_trim_fastq
    barcodes
    r1layout
    r2layout
    mismatch
    splitTag
    mqc_overall_header
    mqc_poswise_header
    mqc_dpmrpm_header

    main:
    EXTRACT_BCS ( 
        ch_trim_fastq,
        barcodes,
        r1layout,
        r2layout,
        mismatch,
        mqc_overall_header,
        mqc_poswise_header
    )

    MAKE_DPM_FASTA ( 
        barcodes,
        splitTag
    )

    TRIM_RPM_DPM ( 
        EXTRACT_BCS.out.reads,
        MAKE_DPM_FASTA.out.fasta
    )

    SPLIT_RPM_DPM ( 
        TRIM_RPM_DPM.out.reads,
        mqc_dpmrpm_header
    )

    SPLIT_RPM_DPM.out.rpm        
        .map { 
            meta, fastq -> 
            meta_new = [:]
            meta_new.id = meta.id
            meta_new.sample = meta.sample
            meta_new.readtype = "rpm"
            [ meta_new, fastq ]
        }
        .set { ch_rpm_fastq }

    SPLIT_RPM_DPM.out.dpm
        .map { 
            meta, fastq -> 
            meta_new = [:]
            meta_new.id = meta.id
            meta_new.sample = meta.sample
            meta_new.readtype = "dpm"
            [ meta_new, fastq ]
        }
        .set { ch_dpm_fastq }

    ch_rpm_fastq
        .mix ( ch_dpm_fastq )
        .set { ch_rpm_dpm }

    FASTQC ( ch_rpm_dpm )

    emit:
    dpm     = ch_dpm_fastq
    rpm     = ch_rpm_fastq
    extract = EXTRACT_BCS.out.stats
    split   = SPLIT_RPM_DPM.out.stats
    trim    = TRIM_RPM_DPM.out.reports
    html    = FASTQC.out.html
    zip     = FASTQC.out.zip
}