def rightpad(string, to_length):
    return string + ' ' * (to_length - len(string))


igenome_prefix = '/{organism}/{provider}/{genome}/'
igenome_assets = {
    'star': dict(assetname = 'star', assetpath = 'Sequence/STARIndex/'),
    'bowtie2': dict(assetname = 'bowtie2', assetpath = 'Sequence/Bowtie2Index/'),
    'gtf': dict(assetname = 'gtf', assetpath = 'Annotation/Genes/genes.gtf'),
    'fasta': dict(assetname = 'fasta', assetpath = 'Sequence/WholeGenomeFasta/genome.fa'),
    'chromSizes': dict(assetname = 'chromSizes', assetpath = 'Sequence/WholeGenomeFasta/GenomeSize.xml')
}

extra_prefix = '${projectDir}/assets/blacklists/'
extra_assets = {
    'blacklist': dict(assetname = 'blacklist', assetpath = '{genome}-blacklist.v2.bed')
}

genomes = {
    'GRCh37': dict(provider = 'Ensembl', organism = 'Homo_sapiens'),
    'GRCh38': dict(provider = 'NCBI', organism = 'Homo_sapiens'),
    'hg19': dict(provider = 'UCSC', organism = 'Homo_sapiens'),
    'hg38': dict(provider = 'UCSC', organism = 'Homo_sapiens'),
    'GRCm38': dict(provider = 'NCBI', organism = 'Mus_musculus'),
    'mm10': dict(provider = 'UCSC', organism = 'Mus_musculus'),
    'ce10': dict(provider = 'UCSC', organism = 'Caenorhabditis_elegans'),
    'dm6': dict(provider = 'UCSC', organism = 'Drosophila_melanogaster')
}

filehead = 'params {\n\tgenomes {\n'
entryhead = "\t\t'{genome}'"
assetstring = '\t\t\t{assetname} = "{prefix}{assetpath}"'

filestring = filehead
max_asset_length = max(
    max(len(k) for k in d.keys()) 
    for d 
    in [igenome_assets, extra_assets]
)
for genome, attr_dict in genomes.items():
    prefix = '${params.igenomes_base}' + igenome_prefix.format(
        genome = genome,
        **attr_dict
    )
    assets = '\n'.join(
        assetstring.format(
            prefix = prefix, 
            assetname = rightpad(asset_dict['assetname'], max_asset_length + 1),
            assetpath = asset_dict['assetpath']
        )
        for _, asset_dict
        in igenome_assets.items()
    )

    assets += '\n' + '\n'.join(
        assetstring.format(
            prefix = extra_prefix, 
            assetpath = asset_dict['assetpath'].format(genome = genome),
            assetname = rightpad(asset_dict['assetname'], max_asset_length + 1)
        )
        for _, asset_dict
        in extra_assets.items()
    )
    entry = entryhead.format(genome = genome) + ' {\n' + assets + '\n\t\t}\n'
    filestring += entry

filestring += '\t}\n}'

with open('igenomes.config', 'w') as file:
    file.write(filestring)
    