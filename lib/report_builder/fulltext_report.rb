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
  class FulltextReport
    include ReportAbstract
    attr_reader  :cd_h, :ars, :analysis_rs, :fields
    def initialize(sr,app)
      @sr=sr
      @app=app
      @ars=AnalysisSystematicReview.new(sr)
      @cd_h=CanonicalDocument.where(:id=>@sr.cd_id_by_stage(:report)).to_hash
      @analysis_rs=@sr.analysis_cd
      @fields=@sr.fields.to_hash(:name)
    end

    def output(format)
      send("output_#{format}".to_sym)
    end


    def output_excel_download
      app.headers 'Content-Type' => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      app.headers 'Content-Disposition' => "attachment; filename=fulltext_report_#{@sr[:id]}.xlsx"
      create_excel
    end
    # TODO: Create a new class on directory 'fulltext_report' and replace rubyXL for axlsx (much efficient!)
    def create_excel
      require 'rubyXL'
      workbook = RubyXL::Workbook.new

      # First, we process the inline codes
      #
      #     %table.tablesorter

      ws_ic = workbook.worksheets[0]
      ws_ic.sheet_name=I18n::t("fulltext_report.inline_code")
      create_excel_inlines_codes(ws_ic)
      ws_cf=workbook.add_worksheet(I18n::t("fulltext_report.custom_form"))
      create_excel_custom_form(ws_cf)
      workbook.stream
    end

    def create_excel_inlines_codes(ws)
      ws.change_row_bold(0,true)
      ws.change_column_width(0,20)
      ws.change_column_width(1,20)
      ws.change_column_width(2,5)
      ws.change_column_width(3,5)
      ws.change_column_width(4,60)
      ws.change_column_width(5,60)

      ws.add_cell(0,0,I18n::t("Fields_analysis"))
      ws.add_cell(0,1,I18n::t("fulltext_report.inline_code"))
      ws.add_cell(0,2,"n")
      ws.add_cell(0,3,I18n::t("fulltext_report.use"))
      ws.add_cell(0,4,I18n::t(:Text))
      ws.add_cell(0,5,I18n::t(:APA_Reference))

      i=1
      self.get_inline_codes.each_pair do |type, codes0|
        name_field=fields[type][:description]
        codes=codes0.sort {|a,b|  a[0]<=>b[0] }
        codes.each do |v|

          v[1].each do |use_data|
            cd_id=use_data[:cd_id]
            cita=cd_h[cd_id].cite_apa_6
            use_i=1
            use_data[:uses].each do |use|
              ws.add_cell(i,0,name_field)
              ws.add_cell(i,1,v[0])
              ws.add_cell(i,2,v[1].length)
              ws.add_cell(i,3,use_i)

              ws.add_cell(i,4,use)
              ws.add_cell(i,5,cita)
              (4..5).each {|j| ws[i][j].change_text_wrap(true) }

              i+=1
              use_i+=1
            end
          end
        end
      end
    end
    def create_excel_custom_form(ws)
      ws.change_row_bold(0,true)
      ws.change_column_width(0,20)
      ws.change_column_width(1,10)
      ws.change_column_width(2,60)
      ws.change_column_width(3,20)
      ws.change_column_width(4,5)
      ws.change_column_width(5,30)

      ws.add_cell(0,0,I18n::t("Fields_analysis"))
      ws.add_cell(0,1,I18n::t("User"))
      ws.add_cell(0,2,I18n::t(:Text))
      ws.add_cell(0,3,I18n::t(:Author))
      ws.add_cell(0,4,I18n::t(:Year))
      ws.add_cell(0,5,I18n::t(:Title))


      i=1
      fields.each_pair do |campo_id, campo|
        @sr.group_users.each do |gu|
          analysis_cd=analysis_rs.where(:user_id=>gu[:id], :canonical_document_id=>cd_h.keys).order(:canonical_document_id)

            if campo[:type]=='select' or campo[:type]=='multiple'
              ws.add_cell(i,0,campo[:description])
              ws.add_cell(i,1,gu[:name])
              ws.add_cell(i,1,"to do")
            else
              analysis_cd.each do |an|
                next if an[campo[:name].to_sym].to_s.chomp==""
                  ws.add_cell(i,0,campo[:description])
                  ws.add_cell(i,1,gu[:name])
                  ws.add_cell(i,2,an[campo[:name].to_sym])
                  ws.add_cell(i,3,cd_h[an[:canonical_document_id]].authors_apa_6)
                  ws.add_cell(i,4,cd_h[an[:canonical_document_id]].year)
                  ws.add_cell(i,5,cd_h[an[:canonical_document_id]].title)
                  (2..5).each {|j| ws[i][j].change_text_wrap(true) }
                i+=1
              end
            end
        end
      end
    end


    def html_field(field_name,user_id)
      type=@fields[field_name].type
      if type=='select'
        html_field_select(field_name,user_id)
      elsif type=='multiple'
        html_field_multiple(field_name,user_id)

      else
        raise 'not implemented'
      end
    end

    def select_info(field_name,user_id)
      field_sym=field_name.to_sym
      values=@analysis_rs.select(:canonical_document_id, field_sym).where(user_id:user_id, :canonical_document_id=>@cd_h.keys).to_hash_groups(field_sym)
      options_h=@fields[field_name].options_as_hash
      #$log.info(options_h)

      values.inject({}) {|ac,v|
        ac[v[0]]={ key:v[0],
                   text:options_h[v[0]],
                   canonical_documents_id:v[1].map {|vv|  vv[:canonical_document_id]}
                  }
        ac
      }

    end
    def multiple_info(field_name,user_id)
      field_sym=field_name.to_sym
      values=@analysis_rs.select(:canonical_document_id, field_sym).where(user_id:user_id, :canonical_document_id=>@cd_h.keys)
      options_h=@fields[field_name].options_as_hash
      values.inject({}) {|ac,v|
        values_included=v[field_sym].nil? ? [] : v[field_sym].split(",")
        ac[v[:canonical_document_id]]=options_h.keys.sort.inject({}) {|ac2,key_opt|
          ac2[key_opt]=values_included.include? key_opt
          ac2
        }
        ac
      }

    end
    def html_field_select(field_name, user_id)
      info=select_info(field_name, user_id)
      app.partial("reports/fulltext_table_select", :locals=>{info:info, cd_h:@cd_h})
    end
    def html_field_multiple(field_name,user_id)
      info=multiple_info(field_name, user_id)
      app.partial("reports/fulltext_table_multiple", :locals=>{info:info, cd_h:@cd_h, options_h:@fields[field_name].options_as_hash})
    end

    def get_inline_codes
      cd_ids = @cd_h.keys
      codes=@fields.keys.inject({}) {|ac,v| ac[v]={}; ac}
      @analysis_rs.where(:canonical_document_id => cd_ids).each do |an|
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