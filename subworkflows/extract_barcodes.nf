include { EXTRACT_BCS               } from '../modules/extract_barcodes/extract_bcs.nf'
include { SPLIT_RPM_DPM             } from '../modules/extract_barcodes/split_rpm_dpm.nf'
include { MAKE_DPM_FASTA            } from '../modules/extract_barcodes/make_dpm_fasta.nf'
include { TRIM_DPM as TRIM_RPM_DPM  } from '../modules/extract_barcodes/trim_dpm.nf'
include { FASTQC                    } from '../modules/fastqc.nf'


def add_rpm_dpm_meta(ch_split_out, readtype) {
    ch_split_out
        .map { 
            meta, fastq -> 
            meta_new = meta.clone()
            meta_new.part = readtype
            [ meta_new, fastq ]
        }
        .set { ch_add_meta }
    
    return ch_add_meta
}


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

    ch_rpm_fastq = add_rpm_dpm_meta ( 
        SPLIT_RPM_DPM.out.rpm,
        'rpm'
    )

    ch_dpm_fastq = add_rpm_dpm_meta ( 
        SPLIT_RPM_DPM.out.dpm,
        'dpm'
    )

    ch_rpm_fastq
        .mix ( ch_dpm_fastq )
        .set { ch_rpm_dpm }

    FASTQC ( ch_rpm_dpm )

    emit:
    dpm     = SPLIT_RPM_DPM.out.dpm
    rpm     = SPLIT_RPM_DPM.out.rpm
    extract = EXTRACT_BCS.out.stats
    split   = SPLIT_RPM_DPM.out.stats
    trim    = TRIM_RPM_DPM.out.reports
    html    = FASTQC.out.html
    zip     = FASTQC.out.zip
}