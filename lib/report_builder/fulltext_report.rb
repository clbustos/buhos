module ReportBuilder
  class FulltextReport
    attr_reader :sr, :app, :cd_h, :ars, :analisis_rs, :fields
    def initialize(sr,app)
      @sr=sr
      @app=app
      @ars=AnalysisSystematicReview.new(sr)
      @cd_h=CanonicalDocument.where(:id=>@sr.cd_id_by_stage(:report)).to_hash
      @analisis_rs=@sr.analysis_cd
      @fields=@sr.fields.to_hash(:name)
    end

    def output(format)
      send("output_#{format}".to_sym)
    end

    def get_inline_codes
      cd_ids = @cd_h.keys
      codes=@fields.keys.inject({}) {|ac,v| ac[v]={}; ac}
      @analisis_rs.where(:canonical_document_id => cd_ids).each do |an|
        @fields.keys.each do |field|
          codes_an=an[field.to_sym].to_s.scan(/\[(.+?)\]/)
          if codes_an.length>0
            codes_an.uniq.each {|code|
              # Busquemos el párrafo donde está el text
              uses=an[field.to_sym].scan(/^.+#{code[0]}.+$/)
              codes[field][code[0]]||=[]
              codes[field][code[0]].push({cd_id:an[:canonical_document_id], uses:uses})
            }
          end

        end
      end
      codes
    end
  end
end