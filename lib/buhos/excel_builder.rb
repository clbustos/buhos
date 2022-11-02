# Copyright (c) 2016-2022, Claudio Bustos Navarrete
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

require 'caxlsx'


#
module Buhos
  require_relative("stages")

  # Builds a Excel for a given systematic review and stage
  class ExcelBuilder
    include StagesMixin

    attr_reader :sr
    attr_reader :stage
    # @param sr [SystematicReview]
    # @param stage [String] name of stage. Could be nil
    def initialize(sr,stage)
      @sr=sr
      @stage=stage
    end
    # Return a string with GraphML XML
    # @return  [String]
    def generate_excel
      @package = Axlsx::Package.new
      wb = @package.workbook
      @blue_cell = wb.styles.add_style  :fg_color => "0000FF", :sz => 12, :alignment => { :horizontal=> :center }
      @wrap_text= wb.styles.add_style({:alignment => {:horizontal => :left, :vertical => :top, :wrap_text => true}} )
      add_canonical_documents(wb)

    end
    def prepare_stream(app)
      app.headers["Content-Disposition"] = "attachment;filename=excel_review_#{@sr.id}_stage_#{@stage}.xlsx"
      app.content_type 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    end
    def stream
      @package.to_stream
    end

    def add_canonical_documents(wb)
      if @stage
        @ars=AnalysisSystematicReview.new(@sr)
        resolutions_val   = @ars.resolution_by_cd(stage)
        resolutions_com = @ars.resolution_commentary_by_cd(stage)
        cds=CanonicalDocument.where(:id=>@sr.cd_id_by_stage(@stage)).order(:title)
        text_decision_cd= Buhos::AnalysisCdDecisions.new(@sr, @stage)
        name_sheet=I18n::t(get_stage_name(stage))
      else
        cds=@sr.canonical_documents.order(:title)
        resolutions_val   = nil
        resolutions_com   = nil
        text_decision_cd= nil
        name_sheet=I18n::t(:All)
      end


      wb.add_worksheet(:name => name_sheet) do |sheet|
        sheet.add_row     [I18n::t(:Id), I18n::t(:Title), I18n::t(:Year), I18n::t(:Author), I18n::t(:Journal),
                           I18n::t(:Volume), I18n::t(:Pages), I18n::t(:Doi), "wos_id","scielo_id","scopus_id", I18n::t(:Abstract),
                           I18n::t(:Decisions),
                           I18n::t(:Resolution), I18n::t(:Commentary)], :style=> [@blue_cell]*15

        cds.each do |cd|
          row_height=((1+cd.abstract.to_s.length)/80.0).ceil*14
          decisions_val = text_decision_cd.nil? ? "" : text_decision_cd.to_text(cd[:id])
          resolution_val=resolutions_val.nil?   ? "" : resolutions_val[cd[:id]]
          resolution_com=resolutions_com.nil?   ? "" : resolutions_com[cd[:id]]
          cd_values=([:id, :title, :year, :author, :journal, :volume, :pages,  :doi, :wos_id, :scielo_id, :scopus_id].map { |v| cd[v].to_s.gsub(/\s+/,' ')})
          sheet.add_row (cd_values+ [cd[:abstract], decisions_val, resolution_val, resolution_com]),
                        :style=>[nil,@wrap_text,nil,nil,nil,nil,nil,nil,nil,nil,nil, @wrap_text, @wrap_text,nil, @wrap_text],
                        :height=>row_height
        end

        sheet.column_info[1].width = 30
        sheet.column_info[2].width = 10
        sheet.column_info[3].width = 20
        sheet.column_info[4].width = 25
        sheet.column_info[5].width = 10
        sheet.column_info[6].width = 10
        sheet.column_info[7].width = 15

        sheet.column_info[8].width = 15
        sheet.column_info[9].width = 15
        sheet.column_info[10].width = 15

        sheet.column_info[11].width = 30
        sheet.column_info[12].width = 30
        sheet.column_info[13].width = 10
        sheet.column_info[14].width = 30

      end
      if @stage

        cd_accepted=CanonicalDocument.where(:id=>@ars.cd_accepted_id(@stage)).order(:title)
        if cd_accepted
          wb.add_worksheet(:name => I18n::t('resolution.yes')) do |sheet|
            sheet.add_row     [I18n::t(:Id), I18n::t(:Title), I18n::t(:Year), I18n::t(:Author),
                               I18n::t(:Journal), I18n::t(:Volume), I18n::t(:Pages), I18n::t(:Doi),
                               I18n::t(:Abstract), I18n::t(:Decisions), I18n::t(:Commentary) ], :style=> [@blue_cell]*10

            cd_accepted.each do |cd|
              row_height=((1+cd.abstract.to_s.length)/80.0).ceil*14
              cd_values=([:id, :title, :year, :author, :journal, :volume, :pages,  :doi].map {|v| cd[v].to_s.gsub(/\s+/,' ')})
              resolution_com=resolutions_com.nil? ? "" : resolutions_com[cd[:id]]
              decisions_val = text_decision_cd.nil? ? "" : text_decision_cd.to_text(cd[:id])
              sheet.add_row (cd_values+[cd[:abstract], decisions_val, resolution_com]),
                            :style=>[nil,@wrap_text,nil,nil,nil,nil,nil,nil,@wrap_text,@wrap_text, @wrap_text], :height=>row_height
            end

            sheet.column_info[1].width = 30
            sheet.column_info[2].width = 10
            sheet.column_info[3].width = 20
            sheet.column_info[4].width = 25
            sheet.column_info[5].width = 10
            sheet.column_info[6].width = 10
            sheet.column_info[7].width = 15
            sheet.column_info[8].width = 30
            sheet.column_info[9].width = 30
          end
        end

      end



    end

  end
end