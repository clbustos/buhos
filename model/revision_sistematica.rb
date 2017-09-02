class Revision_Sistematica < Sequel::Model
  one_to_many :busquedas
  many_to_one :grupo
  many_to_one :trs_foco
  many_to_one :trs_objetivo
  many_to_one :trs_perspectiva
  many_to_one :trs_cobertura
  many_to_one :trs_organizacion
  many_to_one :trs_destinatario

  TRS=["foco","objetivo","perspectiva","cobertura","organizacion","destinatario"]
  TRS_p=["focos","objetivos","perspectivas","coberturas","organizaciones","destinatarios"]

  def grupo_nombre
    grupo.nil? ? "--Sin grupo asignado --" : grupo.name
  end
  def administrador_nombre
    self[:administrador_revision].nil? ? "--Sin administrador asignado --" : Usuario[self[:administrador_revision]].nombre
  end
  def get_nombres_trs
    (0...TRS.length).inject({}) {|ac,v|

      res=$db["trs_#{TRS_p[v]}".to_sym].where(:id=>self["trs_#{TRS[v]}_id".to_sym]).get(:name)
      ac[TRS[v]]=res;
      ac;
    }
  end
  def self.get_revisiones_por_usuario(us_id)
    ids=$db["SELECT r.id FROM revisiones_sistematicas r INNER JOIN grupos_usuarios gu on r.grupo_id=gu.grupo_id WHERE gu.usuario_id='#{us_id}'"].map{|v|v[:id]}
    Revision_Sistematica.where(:id=>ids)
  end
end