// similar to the nf-core module GUNZIP
process GUNZIP {
    tag "${archive}"

    container "docker.io/centos:8"

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
