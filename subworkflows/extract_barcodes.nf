include { EXTRACT_BCS               } from '../modules/extract_barcodes/extract_bcs.nf'
include { SPLIT_RPM_DPM             } from '../modules/extract_barcodes/split_rpm_dpm.nf'
include { MAKE_DPM_FASTA            } from '../modules/extract_barcodes/make_dpm_fasta.nf'
include { TRIM_DPM as TRIM_RPM_DPM  } from '../modules/extract_barcodes/trim_dpm.nf'
include { FASTQC                    } from '../modules/fastqc.nf'


def add_readtype_and_filter(ch, readtype) {
    def ch_return = ch
        .filter { meta, fastq -> fastq.countFastq() > 0 } 
        .map { 
            meta, fastq -> 
            [ meta, readtype, fastq ]
        }

    return ch_return
}


workflow EXTRACT_BARCODES {
    take:
    ch_trim_fastq
    barcodes
    r1layout
    r2layout
    mismatch
    splitTag
    keepSplitTag
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
        splitTag ? splitTag : "DPM"
    )

    TRIM_RPM_DPM ( 
        EXTRACT_BCS.out.reads,
        MAKE_DPM_FASTA.out.fasta
    )

    if ( splitTag ) {

        SPLIT_RPM_DPM ( 
            TRIM_RPM_DPM.out.reads,
            keepSplitTag,
            mqc_dpmrpm_header
        )

        ch_split_stats = SPLIT_RPM_DPM.out.stats

        ch_rpm_fastq = add_readtype_and_filter ( 
            SPLIT_RPM_DPM.out.rpm,
            'rpm'
        )

        ch_dpm_fastq = add_readtype_and_filter (
            SPLIT_RPM_DPM.out.dpm,
            'dpm'
        )

    } else {

        ch_split_stats  = file ( "${workflow.projectDir}/assets/multiqc/dummy_split_stats.txt" )
        ch_rpm_fastq    = Channel.empty()
        ch_dpm_fastq    = add_readtype_and_filter (
            TRIM_RPM_DPM.out.reads,
            'dpm'
        )

    }

    ch_dpm_fastq 
        .mix ( ch_rpm_fastq )
        .set { ch_rpm_dpm }

    FASTQC ( ch_rpm_dpm )

    emit:
    dpm     = ch_dpm_fastq
    rpm     = ch_rpm_fastq
    extract = EXTRACT_BCS.out.stats
    split   = ch_split_stats
    trim    = TRIM_RPM_DPM.out.reports
    html    = FASTQC.out.html
    zip     = FASTQC.out.zip
}