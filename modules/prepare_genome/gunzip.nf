// similar to the nf-core module GUNZIP
process GUNZIP {
    tag "${archive}"

    container "centos:latest"

    input:
    file(archive)

    output:
    path("${gunzip}"), emit: gunzip

    script:
    gunzip = archive.toString() - '.gz'

    """
    gunzip -f ${archive}
    """
}
