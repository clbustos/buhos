class SrField < Sequel::Model
  def self.types_a_sequel(campo)
    if campo[:type] == 'text'
      [campo[:name].to_sym, String, null: true]
    elsif campo[:type] == 'textarea'
      [campo[:name].to_sym, String, text: true, null: true]
    elsif campo[:type] == 'select'
      [campo[:name].to_sym, String, null: true]
    end
  end

  def self.actualizar_tabla(rs)
    table = rs.analysis_cd_tn
    $db.transaction(:rollback => :reraise) do
      #$log.info(table)
      #$log.info()
      if !$db.tables.include? table.to_sym
        $db.create_table? table.to_sym do
          primary_key :id
          foreign_key :user_id, :users, :null => false, :key => [:id]
          foreign_key :canonical_document_id, :canonical_documents, :null => false, :key => [:id]
          index [:canonical_document_id]
          index [:user_id]
        end
      end
      campos_existentes = $db.schema(table.to_sym).inject({}) {|ac, v|
        ac[v[0]] = v[1]; ac
      }
      #$log.info(campos_existentes)
      rs.fields.each do |campo|
        name = campo[:name]
        if campos_existentes[name.to_sym]

        else
          $db.alter_table(table.to_sym) do
            # Mïnimo número de references rtr para revisión de references
            add_column(*SrField.types_a_sequel(campo))
          end
        end
      end
    end
  end



  def options_as_hash
    @options_as_hash ||= self[:options].split(";").inject({}) {|ac, v|
      parts = v.split("=")
      ac[parts[0]] = parts[1]
      ac
    }
  end

end
