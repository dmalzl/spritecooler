import groovy.xml.XmlParser

class SpriteCooler {
    // public methods
        // public methods
    public static void checkParams(params, log) {
        checkGenomeSettings(params, log)
        checkBarcodesSettings(params, log)
    }

    public static int getBaseResolution(resolutions) {
        def reslist = resolutions
            .tokenize(',')
            .collect { resolutionToInt(it) }
            .sort()

        return reslist[0]
    }

    //
    // Get attribute from genome config file e.g. fasta
    // raise error if attribute is not available for given genome
    //
    public static String getGenomeAttribute(params, attribute, log) {
        def val = ''
        if (!params.genomes[ params.genome ].containsKey( attribute )) {
            log.error "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n" +
                "  Genome '${params.genome}' does not contain '${attribute}'.\n" +
                "  Contents of '${params.genome}' are:\n" +
                "  ${params.genomes[ params.genome ].keySet().join(", ")}\n" +
                "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
            System.exit(1)
        }
        val = params.genomes[ params.genome ][ attribute ]
        return val
    }

    //
    // Compute genome length to determine resource needs
    // larger genomes usually need more resources
    //
    public static String getGenomeSizeType(chromSizesFile) {
        def genomeSize = 0
        if (chromSizesFile.endsWith('xml')) {
              def parser = new XmlParser()
              def result = parser.parse( chromSizesFile )
              result
                  .children()
                  .each{ genomeSize += it.@totalBases.toLong() }

        } else {
              new File( chromSizesFile ).eachLine { line -> genomeSize += line.split('\t')[1].toLong() }
        }

        def genomeSizeType = genomeSize > 4000000000 ? "large" : "small"
        return genomeSizeType
    }

        //
    // distributes meta to all items in a collection
    //
    public static ArrayList makeChunks(tuple, chunkSize) {
        def meta    = tuple[0]
        def items   = tuple[1]
        def chunks  = []
        def chunk   = []
        for ( item in items ) {
            chunk.add( item )
            if ( chunk.size == chunkSize ) {
                chunks.add( [ meta, chunk ] )
                chunk = []
            }
        }
        if ( chunk.size != 0 ) {
            chunks.add( [ meta, chunk ] )
        }
        return chunks
    }

    //
    // Print parameter summary log to screen
    //
    public static void paramsSummaryLog(params, dynamic, log) {
        log.info ""
        log.info "++++++++++++++++++++++++++++++++"
        log.info "+                              +"
        log.info "+      SPRITECOOLER ${params.version}     +"
        log.info "+                              +"
        log.info "++++++++++++++++++++++++++++++++"
        log.info ""
        log.info " parameters "
        log.info " ======================"
        log.info " samplesheet              : ${params.samples}"
        log.info " barcodes                 : ${params.barcodes}"
        log.info " r1Layout                 : ${params.r1Layout}"
        log.info " r2Layout                 : ${params.r2Layout}"
        log.info " splitTag                 : ${params.splitTag}"
        log.info " mismatch                 : ${params.mismatch}"
        log.info " minClusterSize           : ${params.minClusterSize}"
        log.info " maxClusterSize           : ${params.maxClusterSize}"
        log.info " mapq                     : ${params.mapq}"
        log.info " savePairs                : ${params.savePairs}"
        log.info " saveQfilteredAlignments  : ${params.saveQfilteredAlignments}"
        log.info " Resolutions              : ${dynamic.resolutions}"
        log.info " baseResolution           : ${dynamic.baseResolution}"
        log.info " Genome                   : ${dynamic.genomeName}"
        log.info " Genome Size              : ${dynamic.genomeSizeType}"
        log.info " Fasta                    : ${dynamic.genomeFasta}"
        log.info " ChromSizes               : ${dynamic.genomeSizes}"
        log.info " Bowtie2 Index            : ${dynamic.bowtie2Index}"
        log.info " STAR Index               : ${dynamic.starIndex}"
        log.info " Blackist                 : ${dynamic.blacklist}"
        log.info " GTF                      : ${dynamic.gtf}"
        log.info " Output Directory         : ${params.outdir}"
        log.info " ======================"
        log.info ""
    }

    // private methods
    //
    // check if specified genome exists in igenomes config
    //
    private static void checkGenomeSettings(params, log) {
        if (!params.genome && !params.fasta) {
            log.error "Neither genome nor fasta file are specified"
            System.exit(1)
        }

        if (params.genomes && params.genome && !params.genomes.containsKey(params.genome)) {
            log.error "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n" +
                "  Genome '${params.genome}' not found in any config files provided to the pipeline.\n" +
                "  Currently, the available genome keys are:\n" +
                "  ${params.genomes.keySet().join(", ")}\n" +
                "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
            System.exit(1)
        }
    }

    private static int resolutionToInt(resolution) {
        def end = resolution.length()
        if (!resolution.isNumber()) {
            end = resolution.length() - 1
        }
        return resolution.substring(0, end).toInteger()
    }
    //
    // check if layout is specified correctly and parse them
    //
    private static Set<String> parseLayout(params, log) {
        Set r1Barcodes = params.r1Layout.tokenize('|')
        Set r2Barcodes = params.r2Layout.tokenize('|')
        return r1Barcodes.plus(r2Barcodes).minus('SPACER')
    }

    private static Set<String> getAvailableBarcodeCategories(barcodes) {
        def file = new File(barcodes)
        def rows = file.readLines()

        Set bcCategories = rows.collect { it.tokenize('\t')[0] }
        return bcCategories.minus('SPACER')
    }

    //
    // parser mismatch param
    //
    private static Set<String> parseMismatch(params, log) {
        if (!params.mismatch) {
            log.error "Mismatches are not set"
            System.exit(1)
        }
        Set mismatchCategories = params.mismatch
            .tokenize(',')
            .collect { it.tokenize(':')[0] }
        
        return mismatchCategories
    }

    //
    // check if mismatches are specified
    //
    private static void checkBarcodesSettings(params, log) {
        if (!params.splitTag) {
            log.warn "--splitTag is not set.\n" + 
            "This will result in skipping the splitting of the FASTQ and will assume that only DNA-DNA contacts are present (i.e. DPM).\n" +
            "If this is not the behaviour you want please make sure --splitTag is set correctly"
        }
        def layoutCategories = parseLayout(params, log)
        def bcCategories = getAvailableBarcodeCategories(params.barcodes)
        def bcintersection = layoutCategories.intersect(bcCategories)
        if (!layoutCategories.equals(bcintersection)) {
            log.error "Not all barcode categories from layout are present in the given barcode file"
            System.exit(1)
        }
        
        def mismatchCategories = parseMismatch(params, log)
        def mmintersection = mismatchCategories.intersect(layoutCategories)
        if (!mismatchCategories.equals(mmintersection)) {
            log.error "Not all used barcode categories have a corresponding mismatch setting"
            System.exit(1)
        }
    }

    //
    // paires up files in a list of files where two successive files are a pair
    //
    private static ArrayList pairFiles(files) {
        def read1 = []
        def read2 = []
        files.eachWithIndex { v, ix -> ( ix & 1 ? read2 : read1 ) << v }
        return [read1, read2].transpose()
    }

}