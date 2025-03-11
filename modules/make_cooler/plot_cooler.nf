process PLOT_COOLER {

    tag "$meta.id"

    conda "${workflow.projectDir}/conda/coolplotter/environment.yml"
    container "docker.io/dmalzl/coolplotter:1.0.0"

    input:
    tuple val(meta), path(mcool)

    output:
    tuple val(meta), path("${meta.id}"),    emit: plots

    script:
    """
    mkdir ${meta.id}

    coolpath=${mcool}::/resolutions/1000000
    for chrom in `cooler dump -t chroms \${coolpath} | cut -f 1`;
    do
        cooler show \\
            --cmap afmhot_r \\
            -o ${meta.id}/${meta.id}_\${chrom}.pdf \\
            \$coolpath \\
            \$chrom
    done
    """
}