module ReportBuilder
  class ProcessReport
    attr_reader :sr, :app, :cd_h, :ars
    def initialize(sr,app)
      @sr=sr
      @app=app
      @ars=AnalisisRevisionSistematica.new(sr)
    end

    def output(format)
      send("output_#{format}".to_sym)
    end

  end
end