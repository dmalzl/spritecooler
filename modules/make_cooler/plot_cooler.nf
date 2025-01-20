process PLOT_COOLER {

    tag "$meta.id"

    conda "${workflow.projectDir}/conda/coolplotter.yml"

    input:
    tuple val(meta), path(mcool)

    output:
    tuple val(meta), path("plots/*pdf"),    emit: plots

    script:
    """
    mkdir plots

    coolfile=${mcool}::/resolutions/1000000
    for chrom in `cooler dump -t chroms | cut -f 1`;
    do
        cooler show \\
            --zmin 0 \\
            --cmap afmhot_r \\
            -o plots/${meta.id}_\${chrom}.pdf \\
            \$coolfile \\
            \$chrom
    done
    """
}