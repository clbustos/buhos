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

class SrField < Sequel::Model
  AVAILABLE_TYPES=[:text,:textarea,:select,:multiple]
  def self.is_valid_type?(type)
    AVAILABLE_TYPES.include? type.to_s.chomp.to_sym
  end
  def self.types_hash
    AVAILABLE_TYPES.inject({}) {|ac,v|
      ac[v]=I18n::t("fields.#{v}")
      ac
    }
  end
  # TODO: Multiple
  def self.types_a_sequel(campo)
    if campo[:type] == 'text'
      [campo[:name].to_sym, String, null: true]
    elsif campo[:type] == 'textarea'
      [campo[:name].to_sym, String, text: true, null: true]
    elsif campo[:type] == 'select'
      [campo[:name].to_sym, String, null: true]
    elsif campo[:type] == 'multiple'
      [campo[:name].to_sym, String, null: true]
    end
  end

  def self.update_table(rs)
    table = rs.analysis_cd_tn
    $db.transaction(:rollback => :reraise) do
      #$log.info(table)
      #$log.info()
      if !$db.tables.include? table.to_sym
        $db.create_table? table.to_sym do
          primary_key :id
          foreign_key :user_id, :users, :null => false, :key => [:id]
          foreign_key :canonical_document_id, :canonical_documents, :null => false, :key => [:id]
          index [:canonical_document_id]
          index [:user_id]
        end
      end
      campos_existentes = $db.schema(table.to_sym).inject({}) {|ac, v|
        ac[v[0]] = v[1]; ac
      }
      #$log.info(campos_existentes)
      rs.fields.each do |campo|
        name = campo[:name]
        if campos_existentes[name.to_sym]

        else
          $db.alter_table(table.to_sym) do
            add_column(*SrField.types_a_sequel(campo))
          end
        end
      end
    end
  end



  def options_as_hash
    @options_as_hash ||= self[:options].split(";").inject({}) {|ac, v|
      parts = v.split("=")
      ac[parts[0]] = parts[1]
      ac
    }
  end
end
