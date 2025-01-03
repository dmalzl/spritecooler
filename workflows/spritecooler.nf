/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
SpriteCooler.checkParams( params, log )

if ( params.genome && params.genomes && !params.igenomes_ignore ) {
    igenomes_bowtie2    = SpriteCooler.getGenomeAttribute(params, 'bowtie2', log)
    igenomes_fasta      = SpriteCooler.getGenomeAttribute(params, 'fasta', log)
    igenomes_chromSizes = SpriteCooler.getGenomeAttribute(params, 'chromSizes', log)

} else {
    igenomes_bowtie2 = ''
    igenomes_fasta = ''
    igenomes_chromSizes = ''

}

// Check input path parameters to see if they exist
checkPathParamList = [
    params.samples,
    params.barcodes,
    params.fasta,
    params.chromSizes,
    igenomes_bowtie2,
    igenomes_fasta,
    igenomes_chromSizes
]

for ( param in checkPathParamList ) { if (param) { file( param, checkIfExists: true ) } }

resolutions = params.resolutions ? params.resolutions : params.defaultResolutions
baseResolution = SpriteCooler.getBaseResolution(resolutions)

// setting up for prepare genome subworkflow
def prepare_genome_for_tools = []

// if we do not have --genome
if ( !params.genome ) {
    // bowtie2 index
    if ( params.fasta ) {
        prepare_genome_for_tools << "bowtie2"

    } else {
        log.error "Neither --genome nor --fasta are specified but needed for bowtie2 index."
        System.exit(1)
    }

    if ( params.chromSizes.endsWith("xml") ) {
        prepare_genome_for_tools << "chromSizes"
    }

// if --genome is specified we check if everything is there
} else {
    if ( !igenomes_bowtie2 ) {
        log.info "Bowtie2 index not found in igenomes config file. Computing from igenomes_fasta"
        prepare_genome_for_tools << "bowtie2"
    }

    if ( igenomes_chromSizes.endsWith("xml") ) {
        prepare_genome_for_tools << "chromSizes"
    }
}

dynamic_params = [:]
dynamic_params.genomeFasta      = params.genome ? igenomes_fasta : params.fasta
dynamic_params.genomeSizes      = params.genome ? igenomes_chromSizes : params.chromSizes
dynamic_params.bowtie2Index     = igenomes_bowtie2 ? igenomes_bowtie2 : "computed from fasta"
dynamic_params.genomeSizeType   = SpriteCooler.getGenomeSizeType( dynamic_params.genomeSizes )
dynamic_params.genomeName       = params.genome ? params.genome : file(dynamic_params.genomeFasta).getSimpleName()
dynamic_params.baseResolution   = baseResolution
dynamic_params.resolutions      = resolutions

SpriteCooler.paramsSummaryLog( params, dynamic_params, log )

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    INSTANTIATE MULTIQC CONFIGS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
ch_multiqc_config   = file ( "${workflow.projectDir}/assets/multiqc/multiqc_config.yml",    checkIfExists: true )
ch_extractbc_mqch   = file ( "${workflow.projectDir}/assets/multiqc/extracbc_header.txt",   checkIfExists: true )
ch_filter_mqch      = file ( "${workflow.projectDir}/assets/multiqc/filter_header.txt",     checkIfExists: true )
ch_pairs_mqch       = file ( "${workflow.projectDir}/assets/multiqc/pairs_header.txt",      checkIfExists: true )

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { INPUT_CHECK        } from '../subworkflows/input_check.nf'
include { PREPARE_GENOME     } from '../subworkflows/prepare_genome.nf'
include { CAT_FASTQ          } from '../modules/cat_fastq.nf'
include { TRIMGALORE         } from '../modules/trimgalore.nf'
include { FASTQC             } from '../modules/fastqc.nf'
include { EXTRACT_BARCODES   } from '../subworkflows/extract_barcodes.nf'
include { ALIGN_FILTER_READS } from '../subworkflows/align_filter_reads.nf'
include { MAKE_PAIRS         } from '../subworkflows/make_pairs.nf'
include { MAKE_COOLER        } from '../subworkflows/make_cooler.nf'
include { MULTIQC            } from '../modules/multiqc.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
workflow SPRITECOOLER {
    ch_input = file( params.samples )

    INPUT_CHECK ( ch_input )
        .reads
        .groupTuple(by: [0])
        .branch {
            meta, fastq ->
                single  : fastq.size() == 1
                    return [ meta, fastq.flatten() ]
                multiple: fastq.size() > 1
                    return [ meta, fastq.flatten() ]
        }
        .set { ch_fastq }

        // prepare genome files
    if (!prepare_genome_for_tools.isEmpty()) {
        ch_genome = PREPARE_GENOME (
            prepare_genome_for_tools,
            dynamic_params
        )

    } else {
        ch_genome = [:]
        ch_genome.index     = file( dynamic_params.bowtie2Index )
        ch_genome.sizes     = file( dynamic_params.genomeSizes )
    }
    // concatenate fastqs of samples with multiple readfiles
    CAT_FASTQ ( ch_fastq.multiple )
        .reads
        .mix ( ch_fastq.single )
        .set { ch_cat_fastq }

    FASTQC ( ch_cat_fastq )

    TRIMGALORE ( ch_cat_fastq )

    EXTRACT_BARCODES (
        TRIMGALORE.out.reads,
        file ( params.barcodes ),
        params.r1Layout,
        params.r2Layout,
        params.mismatch,
        ch_extractbc_mqch
    )

    ALIGN_FILTER_READS (
        EXTRACT_BARCODES.out.reads,
        ch_genome.index,
        params.mapq,
        ch_filter_mqch
    )

    MAKE_PAIRS (
        ALIGN_FILTER_READS.out.bam,
        ch_genome.sizes,
        params.minClusterSize,
        params.maxClusterSize,
        ch_pairs_mqch
    )

    MAKE_COOLER (
        MAKE_PAIRS.out.pairs,
        MAKE_PAIRS.out.bed,
        dynamic_params.baseResolution,
        dynamic_params.resolutions,
        ch_genome.sizes,
        dynamic_params.genomeName,
        params.mergeChunks
    )

    MULTIQC (
        ch_multiqc_config,
        FASTQC.out.zip,
        TRIMGALORE.out.reports,
        TRIMGALORE.out.zip,
        EXTRACT_BARCODES.out.extract,
        EXTRACT_BARCODES.out.trim,
        ALIGN_FILTER_READS.out.align,
        ALIGN_FILTER_READS.out.filtered,
        MAKE_PAIRS.out.stats
    )
}