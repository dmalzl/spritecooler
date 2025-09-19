
include { GUNZIP as GUNZIP_FASTA } from '../modules/prepare_genome/gunzip.nf'
include { XML_TO_TSV             } from '../modules/prepare_genome/xml_to_tsv.nf'
include { BOWTIE2_BUILD_INDEX    } from '../modules/prepare_genome/bowtie2_build_index.nf'
include { STAR_GENOMEGENERATE    } from '../modules/prepare_genome/star_genomegenerate.nf'

workflow PREPARE_GENOME {
    take:
    prepare_genome_for_tools
    dynamic_params

    main:

    // Uncompress genome fasta file if required
    if (params.fasta.endsWith('.gz')) {
        ch_fasta = GUNZIP_FASTA (
             file( dynamic_params.genomeFasta ) // needs to be wrapped in file for GUNZIP to recognize as input
        )

    } else {
        ch_fasta = file( dynamic_params.genomeFasta )
    }

    if ("bowtie2" in prepare_genome_for_tools) {
        ch_bowtie2_index = BOWTIE2_BUILD_INDEX (
            ch_fasta,
            dynamic_params.genomeSizeType
        )

    } else {
        ch_bowtie2_index = file ( dynamic_params.bowtie2Index )
    }

    if ("star" in prepare_genome_for_tools) {
        ch_star_index = STAR_GENOMEGENERATE (
            ch_fasta,
            file( dynamic_params.gtf )
        )

    } else {
        ch_star_index = file ( dynamic_params.starIndex )
    }

    if ("chromSizes" in prepare_genome_for_tools) {
        ch_genome_sizes = XML_TO_TSV (
            file( dynamic_params.genomeSizes )
        )

    } else {
        ch_genome_sizes = file( dynamic_params.genomeSizes )
    }

    emit:
    bowtie2     = ch_bowtie2_index
    star        = ch_star_index
    sizes       = ch_genome_sizes
}
