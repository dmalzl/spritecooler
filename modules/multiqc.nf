process MULTIQC {
    tag 'multiqc'

    conda "${workflow.projectDir}/conda/multiqc.yml"

    input:
    path multiqc_config
    tuple val(meta), path(fastqc_raw,   name: 'fastqc_raw/*')
    tuple val(meta), path(adapter_trim, name: 'adapter_trim/*')
    tuple val(meta), path(fastqc_trim,  name: 'fastqc_trim/*')
    tuple val(meta), path(extract_bc,   name: 'extract_bc/*')
    tuple val(meta), path(dpm_trim,     name: 'dpm_trim/*')
    tuple val(meta), path(bowtie_stats, name: 'bowtie_stats/*')
    tuple val(meta), path(filter_stats, name: 'filter_stats/*')
    tuple val(meta), path(cluster_size, name: 'cluster_size/*')
    tuple val(meta), path(dedup_stats,  name: 'dedup/*')

    output:
    path "*multiqc_report.html", emit: report
    path "*_data"              , emit: data
    path "*_plots"             , emit: plots

    shell:
    '''
    multiqc -f $args $custom_config .
    '''
}