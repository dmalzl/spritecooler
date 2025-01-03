process MULTIQC {
    tag 'multiqc'

    conda "${workflow.projectDir}/conda/multiqc.yml"

    input:
    path multiqc_config
    path('fastqc_raw/*')
    path('adapter_trim/*')
    path('fastqc_trim/*')
    path('extract_bc/*')
    path('dpm_trim/*')
    path('fastqc_dpm/*')
    path('bowtie_stats/*')
    path('filter_stats/*')
    path('cluster_size/*')
    path('dedup/*')

    output:
    path "*multiqc_report.html", emit: report
    path "*_data"              , emit: data
    path "*_plots"             , emit: plots

    shell:
    '''
    multiqc -f .
    '''
}