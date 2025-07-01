process XML_TO_TSV {

      tag "xml2tsv"

      conda "${workflow.projectDir}/conda/spritefridge/environment.yml"
      container "docker.io/dmalzl/spritefridge:1.4.0"

      input:
      file(chromSizeXML)

      output:
      path("chromSizes.tsv"), emit: sizes

      script:
      """
      xml2tsv.py ${chromSizeXML} tmp_chromsizes.tsv
      sort -V -k1,1 tmp_chromsizes.tsv > chromSizes.tsv
      """
}
