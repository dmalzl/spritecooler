/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
SpriteCooler.checkParams( params, log )

if ( params.genome && params.genomes && !params.igenomes_ignore ) {
    igenomes_bowtie2    = SpriteCooler.getGenomeAttribute(params, 'bowtie2')
    igenomes_fasta      = SpriteCooler.getGenomeAttribute(params, 'fasta')
    igenomes_chromSizes = SpriteCooler.getGenomeAttribute(params, 'chromSizes')

} else {
    igenomes_bowtie2 = ''
    igenomes_fasta = ''
    igenomes_chromSizes = ''

}

// Check input path parameters to see if they exist
checkPathParamList = [
    params.input,
    params.barcodes,
    params.fasta,
    params.chromSizes,
    igenomes_bowtie2,
    igenomes_fasta,
    igenomes_chromSizes
]

for ( param in checkPathParamList ) { if (param) { file( param, checkIfExists: true ) } }

if ( params.resolutions ) {
    resolutions = WorkflowHicer.makeResolutionsUnique(
        params.defaultResolutions + ',' + params.resolutions
    )

} else {
    resolutions = params.defaultResolutions
}

resolutionsList = WorkflowHicer.makeResolutionList( resolutions )
baseResolution = resolutionsList[0]

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
dynamic_params.genomeSizeType   = WorkflowHicer.getGenomeSizeType( dynamic_params.genomeSizes )
dynamic_params.genomeName       = params.genome ? params.genome : file(dynamic_params.genomeFasta).getSimpleName()
dynamic_params.baseResolution   = baseResolution
dynamic_params.resolutions      = resolutions

SpriteCooler.paramsSummaryLog( params, dynamic_params, log )

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { INPUT_CHECK        } from '../subworkflows/input_check.nf'
include { PREPARE_GENOME     } from '../subworkflows/prepare_genome.nf'
include { CAT_FASTQ          } from '../modules/cat_fastq.nf'
include { TRIM_GALORE        } from '../modules/trim_galore.nf'
include { MAKE_DPM_FASTA     } from '../modules/make_dpm_fasta.nf'
include { TRIM_DPM           } from '../modules/trim_dpm.nf'
include { BOWTIE2_ALIGN      } from '../modules/bowtie2_align.nf'
include { MAKE_PAIRS         } from '../subworklows/make_pairs.nf'
include { MAKE_COOLER        } from '../subworkflow/make_cooler.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
workflow SPRITECOOLER {
    ch_input = file( params.input )

    INPUT_CHECK ( ch_input )
        .reads
        .groupTuple(by: [0])
        .map {
            meta, fastq -> [ meta, fastq.flatten() ]
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
        ch_genome.index     = file( dynamic_params.bowtie2Index ).getParent()
        ch_genome.sizes     = file( dynamic_params.genomeSizes )
    }
    // concatenate fastqs of samples with multiple readfiles
    CAT_FASTQ ( ch_fastq.multiple )
        .reads
        .mix ( ch_fastq.single )
        .set { ch_cat_fastq }

    // read QC
    TRIM_GALORE ( ch_cat_fastq )
        .reads
        .set { ch_trim_fastq }

    EXTRACT_BARCODES ( 
        ch_trim_fastq,
        params.barcodes,
        params.r1Layout,
        params.r2Layout,
        params.mismatch
    )
    .reads
    .set { ch_extract_fastq }

    MAKE_DPM_FASTA ( params.barcodes )
        .fasta
        .set { ch_dpm_fasta }

    TRIM_DPM ( 
        ch_extract_fastq,
        ch_dpm_fasta
    )
    .reads
    .set { ch_dpm_fastq }

    BOWTIE2_ALIGN (
        ch_dpm_fastq,
        ch_genome.index
    )
    .alignments
    .set { ch_aligned }

    // implement bam stats like nf-core here
    // as subworkflow

    MAKE_PAIRS ( ch_aligned )
    .pairs
    .set { ch_pairs }

    MAKE_COOLER ( ch_pairs )

}