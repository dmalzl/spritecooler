# spritecooler
a cooler way to analyse your SPRITE-seq data

## Introduction
spritecooler is a nextflow pipeline for processing SPRITE-seq data aligned with the 4DN guidelines.
This involves a complete reimplementation of the sprite-pipelines ([1.0](https://github.com/GuttmanLab/sprite-pipeline) and [2.0](https://github.com/GuttmanLab/sprite2.0-pipeline)) in Python
leveraging the [Cooler framework](https://github.com/open2c/cooler) for contact matrix creating, storage and manipulation. This also enables the data to be integrated in existing Hi-C workflows and viewers
such as [higlass](https://higlass.io/)

## Installation
To run the pipeline you need to install [nextflow](https://www.nextflow.io/) (version 23.10.1 or higher) and any distribution of [conda](https://docs.anaconda.com/) (we recommend [miniconda](https://docs.anaconda.com/miniconda/); make sure you have one of the newer versions here also; the pipeline currenly runs on conda environments, may change to containers in the future). 

## Usage
After installing the prerequisites the pipeline can be run with a variation of the following command (this example uses human data from the [original SPRITE-seq paper](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE114242))
```
nextflow run dmalzl/spritecooler \
        --samples samples.csv \
        --barcodes barcodes.tsv \
        --r1Layout DPM \
        --r2Layout 'Y|SPACER|ODD|SPACER|EVEN|SPACER|ODD' \
        --mismatch 'DPM:0,Y:0,EVEN:2,ODD:2' \
        --genome GRCh38
```

Here `samples.csv` is a comma-separated file containing sample information including paths to the files containing the raw sequence data (has to have the follwing format)
```
sample,replicate,fastq_1,fastq_2
SPRITE01,r1,SRR7216005_1.fq.gz,SRR7216005_2.fq.gz
SPRITE01,r1,SRR7216005_1.fq.gz,SRR7216005_2.fq.gz
SPRITE01,r2,SRR7216006_1.fq.gz,SRR7216006_2.fq.gz
SPRITE02,r1,SRR7216007_1.fq.gz,SRR7216007_2.fq.gz
```
The `sample` and `replicate` columns determine the data groupings during the processing. Specifically, all data with same sample and replicate will be concatenated before going through the different processing stages. Data with same sample but different replicate will be merged after generating the base matrix. Irrespective of these mergings the pipeline will also output results for each replicate up to generating the base matrix.

The `barcodes.tsv` is a tab-separated file containing information about the barcodes to extract like barcode category, barcode name and barcode sequence
```
EVEN    Even2Bo1        ATACTGCGGCTGACG
EVEN    Even2Bo5        CTAGGTGGCGGTCTG
EVEN    Even2Bo2        GTGACATTAAGGTTG
EVEN    Even2Bo6        TATCAATGATGGTGC
EVEN    Even2Bo3        CCTCACGTCTAGGCG
```

## Parameters
This section provides an overview of the available command line arguments of the pipeline

### `--samples`
A comma-separated file containing sample information including paths to the files containing the raw sequence data (has to have the follwing format)
```
sample,replicate,fastq_1,fastq_2
SPRITE01,r1,SRR7216005_1.fq.gz,SRR7216005_2.fq.gz
SPRITE01,r1,SRR7216005_1.fq.gz,SRR7216005_2.fq.gz
SPRITE01,r2,SRR7216006_1.fq.gz,SRR7216006_2.fq.gz
SPRITE02,r1,SRR7216007_1.fq.gz,SRR7216007_2.fq.gz
```
The `sample` and `replicate` columns determine the data groupings during the processing. Specifically, all data with same sample and replicate will be concatenated before going through the different processing stages. Data with same sample but different replicate will be merged after generating the base matrix. Irrespective of these mergings the pipeline will also output results for each replicate up to generating the base matrix.

### `--barcodes`
A tab-separated file containing information about the barcodes to extract like barcode category, barcode name and barcode sequence
```
EVEN    Even2Bo1        ATACTGCGGCTGACG
EVEN    Even2Bo5        CTAGGTGGCGGTCTG
EVEN    Even2Bo2        GTGACATTAAGGTTG
EVEN    Even2Bo6        TATCAATGATGGTGC
EVEN    Even2Bo3        CCTCACGTCTAGGCG
```

### `--r1Layout`      
The barcode layout of read1 of the form barcodecategories delimited with '|'. Note that all categories have to present in the barcodes file (except SPACER)
```
--r1Layout DPM
```
### `--r2Layout`      
barcode layout of read2 of the form barcodecategories delimited with '|'. Note that all categories have to present in the barcodes file (except SPACER)
```
--r2Layout 'Y|SPACER|ODD|SPACER|EVEN|SPACER|ODD'
```
            
### `--mismatch` 
specifies the number of mismatches to allow for each barcode category has to be given as a comma-separated list of colon-separated category:nmismatch values
```
--mismatch 'DPM:0,Y:0,EVEN:2,ODD:2'
```

### `--outputDir`      
Directory name to save results to. (default: 'results')

### `--minClusterSize` 
The minimum number of reads a SPRITE cluster must have to be included in the analysis (default: 2)

### `--maxClusterSize` 
The maximum number of reads a SPRITE cluster is allowed to have to be included in the analysis (default: 1000)
            
### `--mergeChunks`    
The number of chunks each dimension of the contact matrix is split into for merging cluster-based coolers. Note this is the square root of the actual number of chunks e.g. setting to 2 will result in 100 chunks (default: 2)

### `--resolutions`    
comma-separated list of resolutions in bp to compute in addition to the default resolutions (see [cooler zoomify](https://cooler.readthedocs.io/en/latest/cli.html#cooler-zoomify); default: 5000N)

### `--genome`      
Name of reference (hg38, mm10, ...) either for usage with iGenomes or for reference of supplied FASTA

### `--fasta`          
Alternatively, path to genome FASTA file to use for alignment

### `--chromSizes`     
A tab-separated file containing chromosome names and their sizes
