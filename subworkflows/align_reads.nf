include { BOWTIE2_ALIGN        } from '../modules/bowtie2_align.nf'
include { FILTER_ALIGNMENTS    } from '../modules/filter_alignments.nf'

workflow ALIGN_READS {
    take:
    ch_dpm_fastq
    bowtie2Index,
    minMapQ

    main:
    BOWTIE2_ALIGN (
        ch_dpm_fastq,
        bowtie2Index
    )

    FILTER_ALIGNMENTS ( 
        BOWTIE2_ALIGN.out.bam,
        minMapQ
    )

    emit:
    bam = SAMTOOLS_SORT_INDEX.out.bam
    stats = FILTER_ALIGNMENTS.out.stats
}