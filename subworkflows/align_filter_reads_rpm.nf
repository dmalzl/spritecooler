include { STAR_ALIGN                                            } from '../modules/align_filter_reads/star_align.nf'
include { FILTER_ALIGNMENTS as FILTER_ALIGNMENTS_RPM            } from '../modules/align_filter_reads/filter_alignments.nf'
include { FILTER_MASKED_REGIONS as FILTER_MASKED_REGIONS_RPM    } from '../modules/align_filter_reads/filter_masked_regions.nf'

workflow ALIGN_FILTER_READS_RPM {
    take:
    ch_rpm_fastq
    starIndex
    minMapQ
    blacklist
    mqc_filter_header
    mqc_mask_header

    main:
    STAR_ALIGN (
        ch_rpm_fastq,
        starIndex
    )

    FILTER_ALIGNMENTS_RPM ( 
        STAR_ALIGN.out.bam,
        minMapQ,
        mqc_filter_header
    )

    if ( blacklist.exists() ) {
        FILTER_MASKED_REGIONS_RPM (
            FILTER_ALIGNMENTS_RPM.out.bam,
            blacklist,
            mqc_mask_header
        )
        ch_mask_bam     = FILTER_MASKED_REGIONS_RPM.out.bam
        ch_mask_stats   = FILTER_MASKED_REGIONS_RPM.out.stats
        
    } else {
        ch_mask_bam     = FILTER_ALIGNMENTS_RPM.out.bam
        ch_mask_stats   = Channel.empty()
    }

    emit:
    bam         = ch_mask_bam
    align       = STAR_ALIGN.out.log
    filtered    = FILTER_ALIGNMENTS_RPM.out.stats
    masked      = ch_mask_stats
}