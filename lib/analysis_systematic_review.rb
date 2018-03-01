require_relative 'analysis_sr_stage_mixin'

# A Facade pattern class
# Shows general statistics for systematic reviews and
# for each article

class AnalysisSystematicReview
  include AnalysisSrStageMixin
  include Buhos::StagesMixin
  attr_reader :rs
  # Id for canonical documents associated to records
  attr_reader :cd_reg_id
  # Id for canonical documents associated to references
  attr_reader :cd_ref_id
  # Id for all canonical documents
  attr_reader :cd_todos_id
  # References between canonical documents
  attr_reader :rec
  # Hash for canonical documents, with incoming citations
  attr_reader :ref_cuenta_entrada
  # Hash for canonical documents, with out citations
  attr_reader :ref_cuenta_salida
  #
  # @param rs object Systematic_Review
  def initialize(rs)
    @rs=rs
    process_basic_indicators
    process_cite_number
    procesar_resoluciones
  end
  def cd_hash
    @rs.cd_hash
  end
  def cd_count_entrada(id)
    @ref_cuenta_entrada[id]
  end

  def cd_count_entrada_rtr(id)
    @cd_referencia_rtr[id]
  end

  def cd_count_salida(id)
    @ref_cuenta_salida[id]
  end

  def cd_count_ref
    @cd_ref_id.length
  end

  def cd_count_reg
    @cd_reg_id.length
  end

  # Señala si un cd es parte de un registro,
  # es decir, si aparece en alguna de las busquedas
  def cd_en_registro?(id)
    @cd_reg_id.include? id
  end
  # Señala si un cd es parte de una referencia# Es decir, en algún momento fue citado por alguien.
  def cd_en_referencia?(id)
    @cd_ref_id.include? id
  end
  def cd_count_total
    @cd_todos_id.length
  end


def process_basic_indicators
  @cd_reg_id=@rs.cd_registro_id
  @cd_ref_id=@rs.cd_referencia_id
  @cd_todos_id=@rs.cd_todos_id
  @rec=@rs.referencias_entre_canonicos
end

private :process_basic_indicators

def process_cite_number
  @ref_cuenta_entrada=@rec.to_hash_groups(:cd_destino).inject({}) {|ac, v|
    ac[v[0]]=v[1].length; ac
  }
  @ref_cuenta_salida=@rec.to_hash_groups(:cd_origen).inject({}) {|ac, v|
    ac[v[0]]=v[1].length; ac
  }


  #cd[:n_referencias_rtr]


  @cd_referencia_rtr = @rs.cuenta_referencias_rtr.inject({}){|ac,v|
    ac[v[:cd_destino]]=v[:n_referencias_rtr];ac
  }


end

private :process_cite_number

def procesar_resoluciones
  @cd_resoluciones=get_stages_ids.inject({}) do |ac,etapa|
    ac[etapa]=Resolucion.where(:revision_sistematica_id=>@rs.id, :etapa=>etapa.to_s).as_hash(:canonico_documento_id)
    ac
  end
end

private :procesar_resoluciones

def cd_in_resolution_stage?(id, etapa)
  @cd_resoluciones[etapa.to_sym][id].nil? ? false : @cd_resoluciones[etapa.to_sym][id][:resolucion] == 'yes'
end

def more_cited(n=20)
  @ref_cuenta_entrada.sort_by {|a| a[1]}.reverse[0...n]
end
def with_more_references(n=20)
  @ref_cuenta_salida.sort_by {|a| a[1]}.reverse[0...n]
end

def pattern_order(a)
  - (1000*a["yes"].to_i + 100*a["no"].to_i + 10*a["undecided"].to_i + 1*a["ND"].to_i)
end


def pattern_name(a)
  Decision::N_EST.map {|key,nombre|
    "#{::I18n::t(nombre)}:#{a[key]}"
  }.join(";")
end

def pattern_id(a)
  Decision::N_EST.keys.map {|key|
    "#{key}_#{a[key]}"
  }.join("__")
end

def pattern_from_s(texto)
  texto.split("__").inject({}){|ac,v|
    key,value=v.split("_")
    ac[key]=value.to_i
    ac
  }
end


end
