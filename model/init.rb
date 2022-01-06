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

# encoding:utf-8
require 'sequel'
require 'logger'

require 'dotenv'

require_relative "../lib/buhos/dbadapter"
if ENV['RACK_ENV'].to_s != "test"
  Dotenv.load("../.env")
end


module Buhos

  def self.connect_to_db(db,keep_reference=true)

    $db.disconnect if !$db.nil? and $db.is_a? Sequel::Database
    if db.is_a? Sequel::Database or db.is_a? Buhos::DBAdapter
      $db=db
    else
      $db=Sequel.connect(db, :encoding => 'utf8',:reconnect=>true, :keep_reference=>keep_reference)
    end



    begin
      $db.run("SET NAMES UTF8")
    rescue Sequel::DatabaseError
      # Not available
    end
    begin
      $db.run("PRAGMA encoding='UTF-8'")
    rescue Sequel::DatabaseError
      # Not available
    end

    $log_sql = Logger.new(File.dirname(__FILE__)+'/../log/app_sql.log')
    $db.loggers << $log_sql
    $db
  end
end

#$log.info(ENV['RACK_ENV'])
#$log.info(ENV['DATABASE_URL'])

Sequel::Model.plugin :force_encoding, 'UTF-8' if RUBY_VERSION>="1.9"
# Bad, isn't?

if ENV['JAWSDB_URL'] and ENV['USE_JAWSDB']=='true'
  url_mysql= ENV['JAWSDB_URL'].sub("mysql:","mysql2:")
  Buhos.connect_to_db(url_mysql)
else
  Buhos.connect_to_db(ENV['DATABASE_URL'], ENV['RACK_ENV'].to_s != "test")
  $log.info("Init app connects to :#{ENV['DATABASE_URL']}")
end


#before do
#  content_type :html, 'charset' => 'utf-8'
#end





Sequel.inflections do |inflect|
  inflect.irregular 'criterion','criteria'
  inflect.irregular 'srcriterion','srcriteria'
  inflect.irregular 'cdcriterion','cdcriteria'

  inflect.irregular 'quality_criterion','quality_criteria'
  inflect.irregular 'sr_quality_criterion','sr_quality_criteria'
  inflect.irregular 'cd_quality_criterion','cd_quality_criteria'


  # inflect.irregular 'rol','roles'
  # inflect.irregular 'configuracion','configuraciones'
  # inflect.irregular 'authorizations_rol','authorizations_roles'
  # inflect.irregular 'grupo_usuario','groups_users'
  # inflect.irregular 'revision_sistematica','.systematic_reviews'
  # inflect.irregular 'trs_organizacion','trs_organizaciones'
  # inflect.irregular 'bibliographical_database','bibliographic_databases'
  # inflect.irregular 'canonical_document','canonical_documents'
  # inflect.irregular 'reference_registro', 'records_references'
  # inflect.irregular 'decision', 'decisions'
  # inflect.irregular 'resolution', 'resolutions'
  # inflect.irregular 't_clase', 't_clases'
  # inflect.irregular 'tag_en_cd', 'tag_in_cds'
  # inflect.irregular 'tag_en_clase', 'tag_in_classes'
  # inflect.irregular 'tag_en_reference_bw_cn', 'tags_en_references_bw_cn'
  # inflect.irregular 'mensaje_rs', 'mensajes_rs'
  # inflect.irregular 'mensaje_rs_visto', 'mensajes_rs_vistos'
  # inflect.irregular 'archivo_cd', 'file_cds'
  # inflect.irregular 'archivo_rs', 'file_rs'
  # inflect.irregular 'asignacion_cd','allocation_cds'
  # inflect.irregular 'tag_en_reference_bw_cn', 'tags_en_references_bw_cn'
end

