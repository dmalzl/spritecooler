process XML_TO_TSV {

      tag "xml2tsv"

      conda "${workflow.projectDir}/conda/spritefridge/environment.yml"
      container "docker.io/dmalzl/spritefridge:1.4.1"

      input:
      file(chromSizeXML)

      output:
      path("chromSizes.tsv"), emit: sizes

      script:
      """
      xml2tsv.py ${chromSizeXML} tmp_chromsizes.tsv
      sort -k1,1 -k2,2n tmp_chromsizes.tsv > chromSizes.tsv
      """
}
