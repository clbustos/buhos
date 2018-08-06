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

# File stored on Buhos.
#
# I named it IFile, to not collide with base Class File.
# Every file is indexed by its hash (SHA256), calculated using the
# content of the file.
class IFile < Sequel::Model(:files)
  # @param file_uploaded as passed from Rack to the route
  # @param systematic_review  [SystematicReview]
  # @param basedir basedir where to store files
  # @param cd [CanonicalDocument]
  # @return Result
  def self.add_on_sr(file_uploaded, systematic_review, basedir, cd = nil)
    result=Result.new
    $db.transaction do
      filename=file_uploaded[:filename].gsub(/[^A-Za-z0-9\.-_]/,"")
      filetype=file_uploaded[:type]
      if filetype=="application/zip" # @todo Unzip the file if is an archiver
      else

        file_id = create_file_on_system(basedir, file_uploaded, filename, filetype)

        archivo_rs_o=FileSr.where(:file_id=>file_id,:systematic_review_id=>systematic_review[:id])

        if archivo_rs_o.empty?
          FileSr.insert(:file_id=>file_id,:systematic_review_id=>systematic_review[:id])
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

  # Create a file on system. Add the uploaded file to
  # basedir, and creates a {IFile} object
  # @param basedir Base directory for files
  # @param file_uploaded as rack uploaded file
  # @param filename, as wanted on the system
  # @param filetypem as provided by mime types
  # @return file_id Id attribute from {IFile} object
  private
  def self.create_file_on_system(basedir, file_uploaded, filename, filetype)
    sha256 = Digest::SHA256.file(file_uploaded[:tempfile]).hexdigest
    #fp=File.open(archivo[:tempfile],"rb")
    archivo_o = IFile.where(:sha256 => sha256)

    if archivo_o.empty?
      file_path = "#{sha256[0]}/#{filename}"
      ruta_completa = "#{basedir}/#{file_path}"
      FileUtils.mkdir_p File.dirname(ruta_completa) unless File.exist?(File.dirname(ruta_completa))
      FileUtils.cp file_uploaded[:tempfile], ruta_completa
      file_id = IFile.insert(:filetype => filetype, :filename => filename, :file_path => file_path, :sha256 => sha256)
    else
      file_id = archivo_o.first[:id]
    end
    file_id
  end
end

class FileCd < Sequel::Model

end

class FileSr < Sequel::Model
  # Retrieve {IFile}s without a cd assigned to it
  # @param [Integer] a {SystematicReview} id
  def self.files_wo_cd(sr_id)
    IFile.join(:file_srs, :file_id=>:id).left_join(:file_cds, :file_id=>:file_id).where(:systematic_review_id=>sr_id,:canonical_document_id=>nil).select_all(:files)
  end
end
