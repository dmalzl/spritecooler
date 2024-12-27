class Main {
    //
    // Print help to screen if required
    //
    public static void help(log) {
        log.info"""
        ================================================================
         spritecooler
        ================================================================
         DESCRIPTION

         Basic processing of HiC data.

         Usage:
         nextflow run pavrilab/hicer-nf

         Options:
            --samples        Tab-delimited text file specifying the samples
                             to be processed. (default: 'samples.txt')
                             The following columns are required:
                                - sample: name of the sample from which the replicate was taken (used to merge coolers)
                                - replicate: name of replicate
                                - fastq_1: Read file with first read mates (R1) in fastq(.gz) format
                                - fastq_2: Read file with second read mates (R2) in fastq(.gz) format

            --barcodes       Tab-delimited file containing barcodes to match when parsing the barcodes from the reads
                             needs to contain three columns in this order barcodecategory, barcodename, barcodesequence but without the header

            --r1Layout       barcode layout of read1 of the form barcodecategories delimited with '|'
                             note that all categories have to present in the barcodes file (except SPACER)

            --r2Layout       barcode layout of read2 of the form barcodecategories delimited with '|'
                             note that all categories have to present in the barcodes file (except SPACER)
            
            --mismatch       specifies the number of mismatches to allow for each barcode category
                             has to be given as a comma-separated list of colon-separated category:nmismatch values
                             e.g. category1:0,category2:2,...

            --outputDir      Directory name to save results to. (default: 'results')

            --minClusterSize minimum number of reads a SPRITE cluster must have to be included in the analysis (default: 2)

            --maxClusterSize maximum number of reads a SPRITE cluster is allowed to have to be included in the analysis (default: 1000)
            
            --mergeChunks    number of chunks each dimension of the contact matrix is split into for merging cluster-based coolers
                             Note this is the square root of the actual number of chunks e.g. setting to 10 will result in 100 chunks (default: 10)

            --resolutions    comma-separated list of resolutions in bp to compute in addition to the default resolutions
    			                   default resolutions are 5000,10000,25000,50000,100000,250000,500000,1000000 and resolutions
    			                   specified via this parameter will be added to this list


         References:
            --genome         Name of reference (hg38, mm10, ...)
            --fasta          Alternatively, path to genome fasta file which will be digested
            --chromSizes     tab-separated file containing chromosome names and their sizes

         Profiles:
            standard         local execution
            singularity      local execution with singularity
            cbe              CBE cluster execution with singularity

         Docker:
         dmalzl/spritecooler:latest

         Authors:
         Daniel Malzl (daniel@lbi-netmed.com)
        """.stripIndent()
    }

    //
    // Validate parameters and print summary to screen
    //
    public static void initialise(workflow, params, log) {
        // Print help to screen if required
        if (params.help) {
            log.info help(log)
            System.exit(0)
        }

        // Check that a -profile or Nextflow config has been provided to run the pipeline
        checkConfigProvided(workflow, log)

        // Check input has been provided
        if (!params.input) {
            log.error "Please provide an input samplesheet to the pipeline e.g. '--samples samplesheet.csv'"
            System.exit(1)
        }
    }

    //
    //  Warn if a -profile or Nextflow config has not been provided to run the pipeline
    //
    public static void checkConfigProvided(workflow, log) {
        if (workflow.profile == 'standard' && workflow.configFiles.size() <= 1) {
            log.warn "[$workflow.manifest.name] You are attempting to run the pipeline without any custom configuration!\n\n" +
                "This will be dependent on your local compute environment but can be achieved via one or more of the following:\n" +
                "   (1) Using an existing pipeline profile e.g. `-profile docker` or `-profile singularity`\n" +
                "   (2) Using an existing nf-core/configs for your Institution e.g. `-profile crick` or `-profile uppmax`\n" +
                "   (3) Using your own local custom config e.g. `-c /path/to/your/custom.config`\n\n" +
                "Please refer to the quick start section and usage docs for the pipeline.\n "
        }
    }
}