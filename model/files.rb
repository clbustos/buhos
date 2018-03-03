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

class IFile < Sequel::Model(:files)
  # @return Result
  def self.add_on_sr(archivo,rs,basedir, cd=nil)
    result=Result.new
    $db.transaction do
      filename=archivo[:filename].gsub(/[^A-Za-z0-9\.-_]/,"")
      filetype=archivo[:type]
      if filetype=="application/zip"
      else
        sha256=Digest::SHA256.file(archivo[:tempfile]).hexdigest
        #fp=File.open(archivo[:tempfile],"rb")
        archivo_o=IFile.where(:sha256=>sha256)
        if archivo_o.empty?
          file_path="#{sha256[0]}/#{filename}"
          ruta_completa="#{basedir}/#{file_path}"
          FileUtils.mkdir_p File.dirname(ruta_completa) unless File.exist?(File.dirname(ruta_completa))
          FileUtils.cp archivo[:tempfile],ruta_completa

          file_id=IFile.insert(:filetype=>filetype,:filename=>filename, :file_path=>file_path, :sha256=>sha256)
        else
          file_id=archivo_o.first[:id]
        end

        archivo_rs_o=FileSr.where(:file_id=>file_id,:systematic_review_id=>rs[:id])
        if archivo_rs_o.empty?
          FileSr.insert(:file_id=>file_id,:systematic_review_id=>rs[:id])
        end
        if cd
          archivo_cd_o=FileCd.where(:file_id=>file_id, :canonical_document_id=>cd[:id])
          if archivo_cd_o.empty?
            FileCd.insert(:file_id=>file_id, :canonical_document_id=>cd[:id])
          end
        end
        result.success( I18n::t("archivo.successful_file_added", filename:filename))
      end
    end
    result
  end

  def absolute_path(basedir)
    "#{basedir}/#{self[:file_path]}"
  end
end
class FileCd < Sequel::Model

end

class FileSr < Sequel::Model
  def self.files_sin_cd(rs_id)
    IFile.join(:file_srs, :file_id=>:id).left_join(:file_cds, :file_id=>:file_id).where(:systematic_review_id=>rs_id,:canonical_document_id=>nil).select_all(:files)
  end
end
