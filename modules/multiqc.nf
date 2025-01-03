process MULTIQC {
    tag 'multiqc'

    conda "bioconda::multiqc=1.20"

    input:
    path multiqc_config
    path multiqc_custom_config
    path(fastqc_raw, name: 'fastqc_raw/*')
    path(adapter_trim, name: 'adapter_trim/*')
    path(fastqc_trim, name: 'fastqc_trim/*')
    path(extract_bc, name: 'extract_bc/*')
    path(dpm_trim, name: 'dpm_trim/*')
    path(bowtie_stats, name: 'bowtie_stats/*')
    path(filter_stats, name: 'filter_stats/*')
    path(cluster_size: 'cluster_size/*')

    output:
    path "*multiqc_report.html", emit: report
    path "*_data"              , emit: data
    path "*_plots"             , emit: plots

    script:
    def args = task.ext.args ?: ''
    def custom_config = params.multiqc_config ? "--config $multiqc_custom_config" : ''
    '''
    multiqc -f $args $custom_config .
    '''
}