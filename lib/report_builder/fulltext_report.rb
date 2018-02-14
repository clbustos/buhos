module ReportBuilder
  class FulltextReport
    attr_reader :sr, :app, :cd_h, :ars, :analisis_rs
    def initialize(sr,app)
      @sr=sr
      @app=app
      @ars=AnalisisRevisionSistematica.new(sr)
      @cd_h=Canonico_Documento.where(:id=>@sr.cd_id_por_etapa(:report)).to_hash
      @analisis_rs=@sr.analisis_cd

    end

    def output(format)
      send("output_#{format}".to_sym)
    end

  end
end