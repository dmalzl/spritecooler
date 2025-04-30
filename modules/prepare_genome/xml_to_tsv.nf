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
      xml2tsv.py ${chromSizeXML} chromSizes.tsv
      """
}