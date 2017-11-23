class Rs_Campo <Sequel::Model
  def self.tipos_a_sequel(campo)
    if campo[:tipo]=='text'
      [campo[:nombre].to_sym, String, null:true]
    elsif campo[:tipo]=='textarea'
      [campo[:nombre].to_sym, String, text:true, null:true]
    elsif campo[:tipo]=='select'
      [campo[:nombre].to_sym, String, null:true]
    end
  end
  def self.actualizar_tabla(rs)
    table=rs.analisis_cd_tn
    $db.transaction(:rollback=>:reraise) do
      if $db["SHOW FULL TABLES  LIKE '%#{table}%'"].empty?
        $db.create_table? table.to_sym do
          primary_key :id
          foreign_key :usuario_id, :usuarios, :null=>false, :key=>[:id]
          foreign_key :canonico_documento_id, :canonicos_documentos, :null=>false, :key=>[:id]
          index [:canonico_documento_id]
          index [:usuario_id]
        end
      end
      campos_existentes=$db.schema(table.to_sym).inject({}) {|ac,v|
        ac[v[0]]=v[1];ac
      }
      #$log.info(campos_existentes)
      rs.campos.each do |campo|
        nombre=campo[:nombre]
        if campos_existentes[nombre.to_sym]

        else
          $db.alter_table(table.to_sym) do
            # Mïnimo número de referencias rtr para revisión de referencias
            add_column(*Rs_Campo.tipos_a_sequel(campo))
          end
        end
      end
    end
  end
  true
end
