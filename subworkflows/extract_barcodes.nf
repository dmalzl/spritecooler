include { EXTRACT_BCS        } from '../modules/extract_barcodes/extract_bcs.nf'
include { MAKE_DPM_FASTA     } from '../modules/extract_barcodes/make_dpm_fasta.nf'
include { TRIM_DPM           } from '../modules/extract_barcodes/trim_dpm.nf'
include { FASTQC             } from '../modules/fastqc.nf'

def check_nvalid_reads(summarypath) {
    Channel
        .fromPath ( summarypath ) 
        .splitCsv ( header: false, sep: '\t')
        .map { it -> it[1] }
        .set { summarystats }

    summarystats
        .sum ()
        .set { ntotal }

    summarystats
        .take ( 1 )
        .set { nvalid }

    def percent = nvalid / ntotal * 100
    def pass = false
    if (percent < 1) {
        pass = true
    }
    return pass
}

def log_failed(meta) {
    log.warn "percent valid reads for ${meta.id} below 5%. Skipping for further processing"
}

workflow EXTRACT_BARCODES {
    take:
    ch_trim_fastq
    barcodes
    r1layout
    r2layout
    mismatch
    mqc_overall_header
    mqc_poswise_header

    main:
    EXTRACT_BCS ( 
        ch_trim_fastq,
        barcodes,
        r1layout,
        r2layout,
        mismatch,
        mqc_overall_header,
        mqc_overall_header
    )

    MAKE_DPM_FASTA ( barcodes )

    // filter low valid bc reads
    EXTRACT_BCS.out.summary
        .map { 
            meta, summarypath -> 
            [ meta, check_nvalid_reads ( summarypath ) ] 
        }
        .set { ch_extract_passed }

    EXTRACT_BCS.out.reads
        .join ( ch_extract_passed, by: [0] )
        .branch {
            meta, reads, pass ->
            passed: pass
                return [ meta, reads ]

            failed: !pass
                return [ meta, reads ]
        }
        .set { ch_pass_fail_extract }

    ch_pass_fail_extract
        .map {
            meta, reads -> 
            log_failed ( meta )
        }
        
    TRIM_DPM ( 
        ch_pass_fail_extract.passed,
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