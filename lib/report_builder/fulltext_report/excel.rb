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
require_relative("../../buhos/stages")
#
module ReportBuilder
  class FullTextReport
    class Excel
      include ::Buhos::StagesMixin
      attr_reader :sr
      attr_reader :report
      def self.create(report)
        excel=Excel.new(report)
        excel.create_wb
        excel.stream
      end
      def initialize(report)
        @report=report
        @sr=report.sr
        @package=nil
      end
      def create_wb
        @package = Axlsx::Package.new
        wb = @package.workbook
        @blue_cell = wb.styles.add_style  :fg_color => "0000FF", :sz => 12, :alignment => { :horizontal=> :center }
        @wrap=wb.styles.add_style :alignment=>{:horizontal=>:left, :vertical => :top, :wrap_text=>true}
        add_custom_form(wb)
        add_inline_code(wb)
      end

      def add_custom_form(wb)

        sr_fields=@sr.fields.order(:order)

        header=[I18n::t(:User), I18n::t(:Title), I18n::t(:Author),  I18n::t(:Year), I18n::t(:Abstract)]+sr_fields.map {|field| field.description }
        cols=header.length
        wb.add_worksheet(:name => I18n::t("fulltext_report.custom_form")) do |sheet|
          sheet.add_row header,  :style=> [@blue_cell]*cols
          @sr.group_users.each do |gu|
            analysis_cd=report.analysis_rs.where(:user_id=>gu[:id], :canonical_document_id=>report.cd_h.keys).order(:canonical_document_id)
            analysis_cd.each do |row_analysis|
              cd=report.cd_h[row_analysis[:canonical_document_id]]
              cd_info=[gu[:name], cd.title, cd.authors_apa_6, cd.year,cd.abstract]
              fields_desc=sr_fields.map do |field|
                map_custom_field(row_analysis,field)
              end
              excel_row=cd_info+fields_desc
              sheet.add_row excel_row, :style=>[@wrap]*cols
            end
          end
          ([15,20,20,5, 20]+[30]*sr_fields.count).each_with_index do |width,index|
            sheet.column_info[index].width=width
          end
        end


      end
      def map_custom_field(row_analysis, field)

        if field[:type]=='select' or field[:type]=='multiple'
          row_analysis[field[:name].to_sym]
        else
          row_analysis[field[:name].to_sym]
        end
      end

      def add_inline_code(wb)
        header=[I18n::t("Fields_analysis"), I18n::t("fulltext_report.inline_code"), "n",I18n::t("fulltext_report.uses_inside_reference"), I18n::t(:Text), I18n::t(:APA_Reference) ]
        wb.add_worksheet(:name => I18n::t("fulltext_report.inline_code")) do |sheet|
          sheet.add_row header, :style=> [@blue_cell]*header.length

          report.get_inline_codes.each_pair do |type, codes0|
            name_field=report.fields[type][:description]
            codes=codes0.sort {|a,b|  a[0]<=>b[0] }
            codes.each do |v|
              v[1].each do |use_data|
                cd_id=use_data[:cd_id]
                cita=report.cd_h[cd_id].cite_apa_6
                use_i=1
                use_data[:uses].each do |use|
                  sheet.add_row [name_field, v[0], v[1].length, use_i, use, cita]
                  use_i+=1
                end
              end
            end
          end
          [20,20,5,5,60,60].each_with_index do |width,index|
            sheet.column_info[index].width=width
          end

        end
      end



      def stream
        @package.to_stream
      end







    end
  end
end