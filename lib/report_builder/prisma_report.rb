# Copyright (c) 2016-2018, Claudio Bustos Navarrete
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#
module ReportBuilder
  class PrismaReport
    include ReportAbstract
    def initialize(sr,app)
      @sr=sr
      @app=app
      @ars=AnalysisSystematicReview.new(sr)

    end
    def process_information
      @sources_identification=sr.searches_dataset.inject({}) {|ac,v|
        source=v[:source]
        ac[source]||=0
        ac[source]+=v.records_n
        ac
      }
      @n_rec_database=@sources_identification["database_search"].to_i # records identified on databases
      @n_rec_back_snow=sr.cd_id_by_stage("screening_references").length # records obtained by snowballing
      @n_rec_other=@sources_identification.inject(0) {|ac,v| ac+v[1]} - @n_rec_database+ @n_rec_back_snow
      @n_rec_non_duplicated=sr.cd_id_by_stage("screening_references").length + sr.cd_id_by_stage("screening_title_abstract").length
      @n_rec_screened=@ars.cd_screened_id("screening_references").count+@ars.cd_screened_id("screening_title_abstract").count
      @n_rec_rej_screen=@ars.cd_rejected_id("screening_references").count+@ars.cd_rejected_id("screening_title_abstract").count
      @n_rec_full_assed=sr.cd_id_by_stage("review_full_text").count
      @n_rec_full_rej=@ars.cd_rejected_id("review_full_text").count
      @n_rec_full_ace=@ars.cd_accepted_id("review_full_text").count

      # We need to recover the tag for exclusions
      #
      reason_to_exclude=@ars.cd_rejected_id("review_full_text").map {|v|
        TagBuilder.tag_in_cd(@sr, CanonicalDocument[v]).find_all {
            |vv|  vv.text=~/^ex:/  and vv.mostrar
        }.map {|vv| vv.text.gsub(/^ex:/,'')}.join("; ")
      }
      @reason_to_exclude_count=reason_to_exclude.inject({}) {|ac,v|
        ac[v]||=0
        ac[v]+=1
        ac
      }

      @svg_reasons=@reason_to_exclude_count.map {|v|  "<tspan x='620' dy='1.2em' >#{v[0]} (n = #{v[1]} )</tspan>"}.join("\n")

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