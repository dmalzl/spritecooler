process XML_TO_TSV {

      tag "xml2tsv"

      conda "${NXF_HOME}/assets/dmalzl/spritecooler/conda/spritefridge.yml"

      input:
      file(chromSizeXML)

      output:
      path("chromSizes.tsv"), emit: sizes

      script:
      """
      xml2tsv.py ${chromSizeXML} chromSizes.tsv
      """
}