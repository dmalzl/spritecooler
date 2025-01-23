/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
SpriteCooler.checkParams( params, log )

if ( params.genome && params.genomes && !params.igenomes_ignore ) {
    igenomes_bowtie2    = SpriteCooler.getGenomeAttribute(params, 'bowtie2',    log)
    igenomes_star       = SpriteCooler.getGenomeAttribute(params, 'star',       log)
    igenomes_gtf        = SpriteCooler.getGenomeAttribute(params, 'gtf',        log)
    igenomes_fasta      = SpriteCooler.getGenomeAttribute(params, 'fasta',      log)
    igenomes_chromSizes = SpriteCooler.getGenomeAttribute(params, 'chromSizes', log)
    igenomes_blacklist  = SpriteCooler.getGenomeAttribute(params, 'blacklist',  log)

} else {
    igenomes_bowtie2    = ''
    igenomes_star       = ''
    igenomes_gtf        = ''
    igenomes_fasta      = ''
    igenomes_chromSizes = ''
    igenomes_blacklist  = ''
}

// Check input path parameters to see if they exist
checkPathParamList = [
    params.samples,
    params.barcodes,
    params.fasta,
    params.chromSizes
]

checkPathiGenomes = [
    igenomes_bowtie2,
    igenomes_star,
    igenomes_fasta,
    igenomes_chromSizes
]

for ( param in checkPathParamList ) { if (param) { file( param, checkIfExists: true ) } }
for ( param in checkPathiGenomes  ) { if (param) { file( param, checkIfExists: true ) } }

resolutions = params.resolutions ? params.resolutions : params.defaultResolutions
baseResolution = SpriteCooler.getBaseResolution(resolutions)

// setting up for prepare genome subworkflow
def prepare_genome_for_tools = []

// if we do not have --genome
if ( !params.genome ) {
    // bowtie2 index
    if ( !params.gtf ) {
        log.error "--genome not specified and no GTF given, which is needed for STAR. Exiting!"
        System.exit(1)
    }
    if ( params.fasta ) {
        prepare_genome_for_tools << "bowtie2"
        prepare_genome_for_tools << "star"

    } else {
        log.error "Neither --genome nor --fasta are specified but needed for Bowtie2/STAR index. Exiting!"
        System.exit(1)
    }

    if ( params.chromSizes.endsWith("xml") ) {
        prepare_genome_for_tools << "chromSizes"
    }
}

dynamic_params = [:]
dynamic_params.genomeFasta      = params.genome ? igenomes_fasta : params.fasta
dynamic_params.genomeSizes      = params.genome ? igenomes_chromSizes : params.chromSizes
dynamic_params.bowtie2Index     = igenomes_bowtie2 ? igenomes_bowtie2 : "computed from fasta"
dynamic_params.starIndex        = igenomes_star ? igenomes_star : "computed from fasta and gtf"
dynamic_params.gtf              = params.gtf ? params.gtf : igenomes_gtf
dynamic_params.blacklist        = params.blacklist ? params.blacklist : igenomes_blacklist
dynamic_params.genomeSizeType   = SpriteCooler.getGenomeSizeType( dynamic_params.genomeSizes )
dynamic_params.genomeName       = params.genome ? params.genome : file( dynamic_params.genomeFasta ).getSimpleName()
dynamic_params.baseResolution   = baseResolution
dynamic_params.resolutions      = resolutions

SpriteCooler.paramsSummaryLog ( params, dynamic_params, log )

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    INSTANTIATE MULTIQC CONFIGS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
ch_multiqc_config           = file ( "${workflow.projectDir}/assets/multiqc/multiqc_config.yml",            checkIfExists: true )
ch_extractbc_overall_mqch   = file ( "${workflow.projectDir}/assets/multiqc/extractbc_overall_header.txt",  checkIfExists: true )
ch_extractbc_poswise_mqch   = file ( "${workflow.projectDir}/assets/multiqc/extractbc_poswise_header.txt",  checkIfExists: true )
ch_dpmrpm_mqch              = file ( "${workflow.projectDir}/assets/multiqc/dpmrpm_header.txt",             checkIfExists: true )
ch_alignfilter_mqch         = file ( "${workflow.projectDir}/assets/multiqc/alignfilter_header.txt",        checkIfExists: true )
ch_clustersize_mqch         = file ( "${workflow.projectDir}/assets/multiqc/clustersize_header.txt",        checkIfExists: true )
ch_dedup_mqch               = file ( "${workflow.projectDir}/assets/multiqc/dedup_header.txt",              checkIfExists: true )
ch_mask_mqch                = file ( "${workflow.projectDir}/assets/multiqc/mask_header.txt",               checkIfExists: true )

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { INPUT_CHECK                                   } from '../subworkflows/input_check.nf'
include { PREPARE_GENOME                                } from '../subworkflows/prepare_genome.nf'
include { CAT_FASTQ                                     } from '../modules/cat_fastq.nf'
include { TRIMGALORE                                    } from '../modules/trimgalore.nf'
include { FASTQC                                        } from '../modules/fastqc.nf'
include { EXTRACT_BARCODES                              } from '../subworkflows/extract_barcodes.nf'
include { ALIGN_FILTER_READS as ALIGN_FILTER_READS_DPM  } from '../subworkflows/align_filter_reads.nf'
include { ALIGN_FILTER_READS as ALIGN_FILTER_READS_RPM  } from '../subworkflows/align_filter_reads.nf'
include { MAKE_PAIRS                                    } from '../subworkflows/make_pairs.nf'
include { MAKE_COOLER                                   } from '../subworkflows/make_cooler.nf'
include { MULTIQC                                       } from '../modules/multiqc.nf'

//define some simple utilities
def remove_null(files) {
    def ret = []
    for (file in files) {
        if (!file) continue
        ret.add(file)
    }
    return ret
}

def remove_rpm_dpm_meta(ch_bam) {
    ch_remove_bam = ch_bam
        .map {
            meta, bam -> 
            meta_new = [:]
            meta_new.id = meta.id
            meta_new.sample = meta.sample
            [ meta_new, bam ]
        }

    return ch_remove_bam
}
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
workflow SPRITECOOLER {
    ch_input = file ( params.samples )

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
        ch_genome.bowtie2   = file ( dynamic_params.bowtie2Index )
        ch_genome.star      = file ( dynamic_params.starIndex )
        ch_genome.sizes     = file ( dynamic_params.genomeSizes )
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
        params.splitTag,
        ch_extractbc_overall_mqch,
        ch_extractbc_poswise_mqch,
        ch_dpmrpm_mqch
    )
    
    ALIGN_FILTER_READS_DPM (
        EXTRACT_BARCODES.out.dpm,
        ch_genome.bowtie2,
        params.mapq,
        file ( dynamic_params.blacklist ),
        ch_alignfilter_mqch,
        ch_mask_mqch,
        "DPM"
    )

    ALIGN_FILTER_READS_RPM (
        EXTRACT_BARCODES.out.rpm,
        ch_genome.star,
        params.mapq,
        file ( dynamic_params.blacklist ),
        ch_alignfilter_mqch,
        ch_mask_mqch,
        "RPM"
    )

    ALIGN_FILTER_READS_DPM.out.align
        .mix ( ALIGN_FILTER_READS_RPM.out.align )
        .set { ch_align_stats }

    ALIGN_FILTER_READS_DPM.out.filtered
        .mix ( ALIGN_FILTER_READS_RPM.out.filtered )
        .set { ch_filter_stats }

    ALIGN_FILTER_READS_DPM.out.masked
        .mix ( ALIGN_FILTER_READS_RPM.out.masked )
        .set { ch_mask_stats }

    ch_dpm_bam = remove_rpm_dpm_meta ( ALIGN_FILTER_READS_DPM.out.bam )
    ch_rpm_bam = remove_rpm_dpm_meta ( ALIGN_FILTER_READS_RPM.out.bam )

    ch_dpm_bam
        .join ( ch_rpm_bam, remainder: true )
        .map { it -> [it[0], remove_null(it[1..-1])] }
        .set { ch_bams }

    MAKE_PAIRS (
        ch_bams,
        ch_genome.sizes,
        params.minClusterSize,
        params.maxClusterSize,
        ch_clustersize_mqch,
        ch_dedup_mqch
    )

    MAKE_COOLER (
        MAKE_PAIRS.out.pairs,
        MAKE_PAIRS.out.bed,
        dynamic_params.baseResolution,
        dynamic_params.resolutions,
        ch_genome.sizes,
        dynamic_params.genomeName
    )

    MULTIQC (
        ch_multiqc_config,
        FASTQC.out.zip.collect { it[1].flatten() },
        TRIMGALORE.out.reports.collect { it[1] },
        TRIMGALORE.out.zip.collect { it[1].flatten() },
        EXTRACT_BARCODES.out.extract.collect { it[1] },
        EXTRACT_BARCODES.out.split.collect { it[1] },
        EXTRACT_BARCODES.out.trim.collect { it[1] },
        EXTRACT_BARCODES.out.zip.collect { it[1] },
        ch_align_stats.collect { it[1] },
        ch_filter_stats.collect { it[1] },
        ch_mask_stats.collect { it[1] },
        MAKE_PAIRS.out.sizestats.collect { it[1] },
        MAKE_PAIRS.out.dupstats.collect { it[1] }
    )
}
