# spritecooler
a cooler way to analyse your SPRITE-seq data

## Introduction
spritecooler is a nextflow pipeline for processing SPRITE-seq data aligned with the 4DN guidelines. It was developed be a complete reimplementation of the sprite-pipeline [v1.0](https://github.com/GuttmanLab/sprite-pipeline) (still lacks the RNA-DNA processing part of [v2.0](https://github.com/GuttmanLab/sprite2.0-pipeline)) in nextflow and Python
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
        --genome GRCh38 \
        --genomeMask GRCh38.blacklist.bed
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

## Steps
Executing the above command will run through all necessary steps to process the data from raw reads to balanced and annotated cooler format. A detailed listing of all the main steps can be found below.

1. *Quality control and adapter trimming*
This step will run `fastqc` as well as `trim_galore` to assess the quality of the raw reads and remove any sequencing adapter contamination from the raw sequencing data.
2. *Barcode extraction*
The QCd reads are then processed to extract the used barcode sequence. Only reads with a full complement of barcodes are retained. For this we use a Python reimplementation of the original Guttman Java tool. In theory this reimplementation is should be flexible enough to accomodate any barcoding scheme but has a few quirks that need to be thought of when fiddling with it. The code below shows the main loop the extraction goes through:
```python
for bc_category, min_bc_len, max_bc_len in layout:
        if bc_category.startswith('S'):
                # skip ahead spacer_len bases
                continue

        if bc_category == 'Y':
                # exact match variable length barcodes (dict hashing)
                # NY barcode is either 9 or 10 bases long
                continue

        if bc_cat.startswith('D'):
                # exactly match the DPM sequence (dict hashing)
                continue

        # find matching barcode by use of regular expression
```
So in essence the set number of mismatches allowed do not apply to DPM and NY sequences. A useful thing to keep in mind might be that in the end, only the barcode name is recorded in the read. This means that the barcode category can accomodate more than just barcodes of this category. e.g. adding RPMs to DPM category to allow RNA-DNA interaction data processing etc.
3. *Trimming DPM remnants*
The given DPM barcodes are converted to FASTA format and used with `cutadapt` to remove any 3' DPM contamination from the raw reads after which another `fastqc` run is executed.
4. *Alignment and filtering*
After quality control and barcode extraction, the genomic sequence containing read is aligned to the reference genome. The produced alignments are then filtered such that (i) only primary alignments with a mapping quality higher then the set `--minq` and (ii) only alignments outside of the blacklisted regions (see `--genomeMask`) are retained
5. *Identifying clusters and making pairs files*
The filtered alignments are then processed to identify clusters based on the identified barcode sequences. Since we count an interaction for each pair of reads in a given cluster downweighted by 2/n, where n is the number of reads in the cluster and due to the communtativity of multiplication in a sum we then simply write all read pairs of clusters of the same size to a single pairs file for ingestions with cooler. The generated pairs files for each cluster are also reformated to pairix format for easy ingestion with any other software in the 4DN universe. This step also records the cluster identity of each alignment in the form of a BED file, which is later used to annotate the contact matrices (see step 7).
6. *Generating contact matrices*
Generated pairs files for each cluster size are then ingested with cooler to generate contact matrices for each clustersize. These contact matrices are then subsequently merged by simply summing over their downweighted counts per bin (e.g. for a clustersize of 250 the corresponding matrix is simply multiplied by 2/250 before summing). The resulting merged matrix is then coarsend to different bin sizes (`cooler zoomify`; default: 5000N) and balanced using iterative correction and Knight-Ruiz per chromosome and genomewide.
7. *Annotating cluster identity of contacts per bin*
The last step of the pipeline is adding the cluster identity of the recorded contacts to each bin, which is done by intersecting the aformentioned BED file (see step 5) with the genome bins. The results are then written to the `bins` table of the generated cooler for each bin size. The format of the annotation looks somewhat like this
```
c_2_1,c_8_10,c_5_20,...
```
where each alignment is recorded as `c_<clustersize>_<clusternumber>`. This information can later be used to assess the number of clusters overlapping a given set of regions of interest

The final result of the pipeline is then saved to the folder set with `--outdir` (default: `results`). This includes the balanced and annotated contact matrix (`<outdir>/cool/annotated`), the individual contact matrices for each clustersize as multicooler (`<outdir>/cool/base`; these are raw contacts at base resolution (default: 5kb) without downweighting and no balancing), the filtered alignments (`<outdir>/alignments`) and the respective BED files (`<outdir>/clusterbed`). Optionally, you can also set `--savePairs true` to save the generated pairs files for each cluster and `--saveQfilteredAlignments true` to save alignments before blacklist filtering (`<outdir>/alignments`).

## Parameters
This section provides an overview of the available command line arguments of the pipeline

#### `--samples`
A comma-separated file containing sample information including paths to the files containing the raw sequence data (has to have the follwing format)
```
sample,replicate,fastq_1,fastq_2
SPRITE01,r1,SRR7216005_1.fq.gz,SRR7216005_2.fq.gz
SPRITE01,r1,SRR7216005_1.fq.gz,SRR7216005_2.fq.gz
SPRITE01,r2,SRR7216006_1.fq.gz,SRR7216006_2.fq.gz
SPRITE02,r1,SRR7216007_1.fq.gz,SRR7216007_2.fq.gz
```
The `sample` and `replicate` columns determine the data groupings during the processing. Specifically, all data with same sample and replicate will be concatenated before going through the different processing stages. Data with same sample but different replicate will be merged after generating the base matrix. Irrespective of these mergings the pipeline will also output results for each replicate up to generating the base matrix.

#### `--barcodes`
A tab-separated file containing information about the barcodes to extract like barcode category, barcode name and barcode sequence
```
EVEN    Even2Bo1        ATACTGCGGCTGACG
EVEN    Even2Bo5        CTAGGTGGCGGTCTG
EVEN    Even2Bo2        GTGACATTAAGGTTG
EVEN    Even2Bo6        TATCAATGATGGTGC
EVEN    Even2Bo3        CCTCACGTCTAGGCG
```

#### `--r1Layout`      
The barcode layout of read1 of the form barcodecategories delimited with '|'. Note that all categories have to present in the barcodes file (except SPACER)
```
--r1Layout DPM
```
#### `--r2Layout`      
barcode layout of read2 of the form barcodecategories delimited with '|'. Note that all categories have to present in the barcodes file (except SPACER)
```
--r2Layout 'Y|SPACER|ODD|SPACER|EVEN|SPACER|ODD'
```
            
#### `--mismatch` 
specifies the number of mismatches to allow for each barcode category has to be given as a comma-separated list of colon-separated category:nmismatch values
```
--mismatch 'DPM:0,Y:0,EVEN:2,ODD:2'
```

#### `--minq`
The minimum mapping quality for a given alignment to be retained (default: 20)

#### `--outdir`      
Directory name to save results to. (default: 'results')

#### `--savePairs`
whether to write pairs files to results. set to `--savePairs true` in case you want the pairs files (default: false)

#### `--saveQfilteredAlignments`
whether to also save quality filtered primary alignments. set to `--saveQfilteredAlignments true`(default: false)

#### `--minClusterSize` 
The minimum number of reads a SPRITE cluster must have to be included in the analysis (default: 2)

#### `--maxClusterSize` 
The maximum number of reads a SPRITE cluster is allowed to have to be included in the analysis (default: 1000)

#### `--resolutions`    
comma-separated list of resolutions in bp to compute in addition to the default resolutions (see [cooler zoomify](https://cooler.readthedocs.io/en/latest/cli.html#cooler-zoomify); default: 5000N)

#### `--genome`      
Name of reference (hg38, mm10, ...) either for usage with iGenomes or for reference of supplied FASTA

#### `--fasta`          
Alternatively, path to genome FASTA file to use for alignment

#### `--chromSizes`     
A tab-separated file containing chromosome names and their sizes

#### `--genomeMask`
BED file to use for filtering reads from problematic regions
