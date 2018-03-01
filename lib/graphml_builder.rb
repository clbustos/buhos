class GraphML_Builder
  def initialize(sr, stage)
    @sr=sr
    @stage=stage
  end
  def generate_graphml
    ars=AnalysisSystematicReview.new(@sr)
    if @stage
      cd_hash=Canonico_Documento.where(:id=>@sr.cd_id_by_stage(@stage)).order(:year).as_hash
    else
      cd_hash=@sr.canonicos_documentos.order(:year).as_hash
    end

    head=<<HEREDOC
<?xml version="1.0" encoding="UTF-8"?>
<graphml xmlns="http://graphml.graphdrawing.org/xmlns"
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xsi:schemaLocation="http://graphml.graphdrawing.org/xmlns
http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd">

<key id="d0" for="node" attr.name="doi"        attr.type="string"/>
<key id="d1" for="node" attr.name="title"      attr.type="string"/>
<key id="d2" for="node" attr.name="year"       attr.type="int"/>
<key id="d3" for="node" attr.name="input_n"    attr.type="int"/>
<key id="d5" for="node" attr.name="on_register" attr.type="boolean"/>
<key id="d6" for="node" attr.name="on_reference" attr.type="boolean"/>
<key id="d7" for="node" attr.name="on_title_abstract" attr.type="boolean"/>
<key id="output_n" for="node" attr.name="output_n"   attr.type="int"/>

<graph id="G" edgedefault="directed">

HEREDOC
      nodos=cd_hash.map {|v|
        str="<node id='n#{v[0]}'>"
        if v[1].doi
          str+="<data key='d0'><![CDATA[#{CGI.escapeHTML(v[1].doi)}]]></data>"
        else
          str+="<data key='d0'></data>"
        end
        str+="<data key='d1'><![CDATA[#{CGI.escapeHTML(v[1].title)}]]></data>
<data key='d2'>#{v[1].year.to_i}</data>
<data key='d3'>#{ars.cd_count_entrada(v[0]).to_i}</data>
<data key='output_n'>#{ars.cd_count_salida(v[0]).to_i}</data>
<data key='d5'>#{ars.cd_en_registro?(v[0]) ? "true" : "false"}</data>
<data key='d6'>#{ars.cd_en_referencia?(v[0]) ? "true" : "false"}</data>
<data key='d7'>#{ars.cd_in_resolution_stage?(v[0], "screening_title_abstract") ? "true" : "false"}</data>
</node>"
      }.join("\n")
      edges=ars.rec.find_all{|x| cd_hash[x[:cd_origen]] and cd_hash[x[:cd_destino]] }.map {|v|
        "<edge source='n#{v[:cd_origen]}' target='n#{v[:cd_destino]}' directed='true' />"
      }.join("\n")
      footer="\n</graph>\n</graphml>"
      [head, nodos, edges, footer].join("\n")
  end
end