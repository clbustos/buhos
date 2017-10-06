get '/revision/:id/tags' do |id|
  @revision=Revision_Sistematica[id]

  @etapas_lista={:NIL=>"--Todas--"}.merge(Revision_Sistematica::ETAPAS_NOMBRE)

  @select_etapa=get_xeditable_select(@etapas_lista, "/tags/clases/editar_campo/etapa","select_etapa")
  @select_etapa.nil_value=:NIL
  @tipos_lista={general:"General", documento:"Documento", relacion:"Relación"}

  @select_tipo=get_xeditable_select(@tipos_lista, "/tags/clases/editar_campo/tipo","select_tipo")

  haml %s{revisiones_sistematicas/tags}
end