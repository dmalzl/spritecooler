include { STAR_ALIGN            } from '../modules/align_filter_reads/star_align.nf'
include { FILTER_ALIGNMENTS     } from '../modules/align_filter_reads/filter_alignments.nf'
include { FILTER_MASKED_REGIONS } from '../modules/align_filter_reads/filter_masked_regions.nf'

workflow ALIGN_FILTER_READS {
    take:
    ch_rpm_fastq
    starIndex
    minMapQ
    ch_genome_mask
    mqc_filter_header
    mqc_mask_header

    main:
    STAR_ALIGN (
        ch_dpm_fastq,
        bowtie2Index
    )

    FILTER_ALIGNMENTS ( 
        STAR_ALIGN.out.bam,
        minMapQ,
        mqc_filter_header
    )

    FILTER_MASKED_REGIONS (
        FILTER_ALIGNMENTS.out.bam,
        ch_genome_mask,
        mqc_mask_header
    )

    emit:
    bam         = FILTER_MASKED_REGIONS.out.bam
    align       = STAR_ALIGN.out.log
    filtered    = FILTER_ALIGNMENTS.out.stats
    masked      = FILTER_MASKED_REGIONS.out.stats
}