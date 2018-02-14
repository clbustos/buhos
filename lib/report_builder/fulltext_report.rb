module ReportBuilder
  class FulltextReport
    attr_reader :sr, :app, :cd_h, :ars, :analisis_rs, :fields
    def initialize(sr,app)
      @sr=sr
      @app=app
      @ars=AnalisisRevisionSistematica.new(sr)
      @cd_h=Canonico_Documento.where(:id=>@sr.cd_id_por_etapa(:report)).to_hash
      @analisis_rs=@sr.analisis_cd
      @fields=@sr.campos.to_hash(:nombre)
    end

    def output(format)
      send("output_#{format}".to_sym)
    end

    def get_inline_codes
      cd_ids = @cd_h.keys
      codes=@fields.keys.inject({}) {|ac,v| ac[v]={}; ac}
      @analisis_rs.where(:canonico_documento_id => cd_ids).each do |an|
        @fields.keys.each do |field|
          codes_an=an[field.to_sym].to_s.scan(/\[(.+?)\]/)
          if codes_an.length>0
            codes_an.uniq.each {|code|
              # Busquemos el párrafo donde está el texto
              uses=an[field.to_sym].scan(/^.+#{code[0]}.+$/)
              codes[field][code[0]]||=[]
              codes[field][code[0]].push({cd_id:an[:canonico_documento_id], uses:uses})
            }
          end

        end
      end
      codes
    end
  end
end