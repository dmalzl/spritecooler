include { BOWTIE2_ALIGN        } from '../modules/align_filter_reads/bowtie2_align.nf'
include { FILTER_ALIGNMENTS    } from '../modules/align_filter_reads/filter_alignments.nf'

workflow ALIGN_FILTER_READS {
    take:
    ch_dpm_fastq
    bowtie2Index
    minMapQ
    mqc_header

    main:
    BOWTIE2_ALIGN (
        ch_dpm_fastq,
        bowtie2Index
    )

    FILTER_ALIGNMENTS ( 
        BOWTIE2_ALIGN.out.bam,
        minMapQ,
        mqc_header
    )

    emit:
    bam         = FILTER_ALIGNMENTS.out.bam
    align       = BOWTIE2_ALIGN.out.log
    filtered    = FILTER_ALIGNMENTS.out.stats
}