# Copyright (c) 2016-2023, Claudio Bustos Navarrete
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


require_relative("fulltext_report/excel")

#
module ReportBuilder
  class FulltextReport
    include ReportAbstract
    attr_reader  :cd_h, :ars, :analysis_rs, :fields, :aqc
    def initialize(sr,app)
      @sr=sr
      @app=app
      @ars=AnalysisSystematicReview.new(sr)
      @cd_h=CanonicalDocument.where(:id=>@sr.cd_id_by_stage(:report)).to_hash
      @analysis_rs=@sr.analysis_cd
      @fields=@sr.fields.to_hash(:name)
      @aqc=Buhos::AnalysisQualityCriteria.new(sr)
    end

    def output(format)
      send("output_#{format}".to_sym)
    end


    def output_excel_download
      app.headers 'Content-Type' => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      app.headers 'Content-Disposition' => "attachment; filename=fulltext_report_#{@sr[:id]}.xlsx"
      ReportBuilder::FullTextReport::Excel.create(self)
      #create_excel
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