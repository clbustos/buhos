module ReportBuilder
  class PrismaReport
    attr_reader :sr, :app
    def initialize(sr,app)
      @sr=sr
      @app=app
      @ars=AnalisisRevisionSistematica.new(sr)

    end
    def process_information
      @sources_identification=sr.busquedas_dataset.inject({}) {|ac,v|
        source=v[:source]
        ac[source]||=0
        ac[source]+=v.registros_n
        ac
      }
      @n_rec_database=@sources_identification["database_search"].to_i # records identified on databases
      @n_rec_back_snow=sr.cd_id_por_etapa("revision_referencias").length # records obtained by snowballing
      @n_rec_other=@sources_identification.inject(0) {|ac,v| ac+v[1]} - @n_rec_database+ @n_rec_back_snow
      @n_rec_non_duplicated=sr.cd_id_por_etapa("revision_referencias").length + sr.cd_id_por_etapa("revision_titulo_resumen").length
      @n_rec_screened=@ars.cd_screened_id("revision_referencias").count+@ars.cd_screened_id("revision_titulo_resumen").count
      @n_rec_rej_screen=@ars.cd_rejected_id("revision_referencias").count+@ars.cd_rejected_id("revision_titulo_resumen").count
      @n_rec_full_assed=sr.cd_id_por_etapa("revision_texto_completo").count
      @n_rec_full_rej=@ars.cd_rejected_id("revision_texto_completo").count
      @n_rec_full_ace=@ars.cd_accepted_id("revision_texto_completo").count

      # We need to recover the tag for exclusions
      #
      reason_to_exclude=@ars.cd_rejected_id("revision_texto_completo").map {|v|
        AnalisisTag.tag_en_cd_rs(@sr, Canonico_Documento[v]).find_all {
            |vv|  vv.texto=~/^ex:/  and vv.mostrar
        }.map {|vv| vv.texto.gsub(/^ex:/,'')}.join("; ")
      }
      @reason_to_exclude_count=reason_to_exclude.inject({}) {|ac,v|
        ac[v]||=0
        ac[v]+=1
        ac
      }

      @svg_reasons=@reason_to_exclude_count.map {|v|  "<tspan x='620' dy='1.2em' >#{v[0]} (n = #{v[1]} )</tspan>"}.join("\n")

    end
    def output(format)
      send("output_#{format}".to_sym)
    end

    def output_svg
      app.headers 'Content-Type' => "image/svg+xml"
      create_svg
    end

    def output_svg_download
      app.headers 'Content-Type' => "image/svg+xml"
      app.headers 'Content-Disposition' => "attachment; filename=prisma_flow_diagram_#{@sr[:id]}.svg"
      create_svg
    end

    def create_svg
      process_information
      svg_file=File.path("#{app.dir_base}/config/svg/prisma.svg")
      svg=File.read(svg_file)
      svg.gsub!("%{n1}", @n_rec_database.to_s)
      svg.gsub!("%{n2}", @n_rec_other.to_s)
      svg.gsub!("%{n3}", @n_rec_non_duplicated.to_s)
      svg.gsub!("%{n4}", @n_rec_screened.to_s)
      svg.gsub!("%{n5}", @n_rec_rej_screen.to_s)
      svg.gsub!("%{n6}", @n_rec_full_assed.to_s)
      svg.gsub!("%{n7}", @n_rec_full_rej.to_s)
      svg.gsub!("%{n8}", @n_rec_full_ace.to_s)
      svg.gsub!("%{fte}", @svg_reasons)


      ["Identification","Screening","Eligibility","Included", "Records identified through", "database searching","Additional records identified", "through other sources", "Records after","duplicates removed", "Records screened", "Records excluded", "Full-text articles", "assessed for eligibility", "Full-text articles","excluded", "Studies included in", "qualitative synthesis"].each do |text|
        svg.gsub!(text, I18n::t("prisma_report.#{text}"))
      end



      svg
    end

  end
end