include { BOWTIE2_ALIGN             } from '../modules/align_filter_reads/bowtie2_align.nf'
include { STAR_ALIGN                } from '../modules/align_filter_reads/star_align.nf'
include { FILTER_ALIGNMENTS         } from '../modules/align_filter_reads/filter_alignments.nf'
include { FILTER_MASKED_REGIONS     } from '../modules/align_filter_reads/filter_masked_regions.nf'

workflow ALIGN_FILTER_READS {
    take:
    ch_fastq
    alignIndex
    minMapQ
    blacklist
    mqc_filter_header
    mqc_mask_header
    readtype

    main:
    if (readtype == 'DPM') {
        BOWTIE2_ALIGN (
            ch_fastq,
            alignIndex
        )
        ch_bam          = BOWTIE2_ALIGN.out.bam
        ch_align_stats  = BOWTIE2_ALIGN.out.log
    }

    if (readtype == 'RPM') {
        STAR_ALIGN (
            ch_fastq,
            alignIndex
        )
        ch_bam          = STAR_ALIGN.out.bam
        ch_align_stats  = STAR_ALIGN.out.log
    }

    FILTER_ALIGNMENTS ( 
        ch_bam,
        minMapQ,
        mqc_filter_header
    )

    if ( blacklist.exists() ) {
        FILTER_MASKED_REGIONS (
            FILTER_ALIGNMENTS.out.bam,
            blacklist,
            mqc_mask_header
        )
        ch_mask_bam     = FILTER_MASKED_REGIONS.out.bam
        ch_mask_stats   = FILTER_MASKED_REGIONS.out.stats

    } else {
        ch_mask_bam     = FILTER_ALIGNMENTS.out.bam
        ch_mask_stats   = Channel.empty()
    }

    emit:
    bam         = ch_mask_bam
    align       = ch_align_stats
    filtered    = FILTER_ALIGNMENTS.out.stats
    masked      = ch_mask_stats
}