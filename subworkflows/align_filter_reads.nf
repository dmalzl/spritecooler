include { BOWTIE2_ALIGN         } from '../modules/align_filter_reads/bowtie2_align.nf'
include { FILTER_ALIGNMENTS     } from '../modules/align_filter_reads/filter_alignments.nf'
include { FILTER_MASKED_REGIONS } from '../modules/align_filter_reads/filter_masked_regions.nf'

workflow ALIGN_FILTER_READS {
    take:
    ch_dpm_fastq
    bowtie2Index
    minMapQ
    ch_genome_mask
    mqc_filter_header
    mqc_mask_header

    main:
    BOWTIE2_ALIGN (
        ch_dpm_fastq,
        bowtie2Index
    )

    FILTER_ALIGNMENTS ( 
        BOWTIE2_ALIGN.out.bam,
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
    align       = BOWTIE2_ALIGN.out.log
    filtered    = FILTER_ALIGNMENTS.out.stats
    masked      = FILTER_MASKED_REGIONS.out.stats
}