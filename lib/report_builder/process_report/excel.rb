# Copyright (c) 2016-2021, Claudio Bustos Navarrete
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
  class ProcessReport
    class Excel
      include ::Buhos::StagesMixin
      attr_reader :sr
      attr_reader :report
      def self.create(pr)
        excel=Excel.new(pr)
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
        @blue_cell = wb.styles.add_style  :fg_color => "0000FF", :sz => 14, :alignment => { :horizontal=> :center }
        add_stage(wb,:screening_title_abstract)
        add_stage(wb,:screening_references)
        add_stage(wb,:review_full_text)

      end
      def add_stage(wb,stage)
        cds           = CanonicalDocument.where(:id=>@sr.cd_id_by_stage(stage)).order(:year,:author)
        adu           = report.ars.user_decisions(stage)
        resolutions   = report.ars.resolution_by_cd(stage)

        wb.add_worksheet(:name => I18n::t(get_stage_name(stage))) do |sheet|
          sheet.add_row     [I18n::t(:Canonical_document)]+sr.group_users.map {|user| user[:name]}+[I18n::t(:Resolution)], :style=> [@blue_cell]*(2+sr.group_users.count)

          cds.each do |cd|
          sheet.add_row [cd.ref_apa_6_brief] + @sr.group_users.map {|user| I18n::t(adu[user[:id]][:adu].decision_cd_id(cd[:id]))} + [I18n::t(resolutions[cd[:id]])]
          sheet.column_info.first.width = 50
          end
        end
      end
      def stream
        @package.to_stream
      end

    end
  end
end