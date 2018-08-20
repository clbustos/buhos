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

# Process the incorporation of a file to Buhos
# Could handle upload files, and other types of files
class FileProcessor
  attr_reader :filetype
  attr_reader :filename
  attr_reader :filepath
  attr_reader :file_id
  attr_reader :basedir

  class NoUploadedFilesType < StandardError

  end
  def initialize(file,basedir=nil)
    @basedir=basedir
    @filetype="application/octet-stream"
    @file_id=nil
    if file.is_a? String and File.exist? file # Ok, is a filepath
      require 'mimemagic'
      @filetype=MimeMagic.by_magic(File.open(file)).type
      @filename=File.basename(file)
      @filepath=file
    elsif file.respond_to?("[]") and !file[:tempfile].nil? # Is uploaded
      @filetype=file[:type]
      @filename=file[:filename]
      @filepath=file[:tempfile]
    elsif file.is_a? IFile
      @filetype=file[:typetype]
      @filename=file[:filename]
      @filepath="#{basedir}/#{file[:file_path]}"
      @file_id=file[:id]
    else
      raise "I don't know what type of file is it"
    end
    create_file_on_system unless @file_id
    @filename=@filename.gsub(/[^A-Za-z0-9\.-_]/,"")
  end



  def add_to_sr(systematic_review)
    $db.transaction do
      archivo_rs_o=FileSr.where(:file_id=>file_id,:systematic_review_id=>systematic_review[:id])
      if archivo_rs_o.empty?
         FileSr.insert(:file_id=>file_id,:systematic_review_id=>systematic_review[:id])
      end
    end
  end

  def add_to_cd(cd)
    $db.transaction do
      archivo_cd_o=FileCd.where(:file_id=>file_id, :canonical_document_id=>cd[:id])
      if archivo_cd_o.empty?
        FileCd.insert(:file_id=>file_id, :canonical_document_id=>cd[:id])
      end
    end
  end

  def add_to_record_search(search,record)
    $db.transaction do
      raise NoUploadedFilesType, "Search should be uploaded_files type" unless search.is_type?(:uploaded_files)
      rec_sec=RecordsSearch[:record_id=>record[:id], :search_id=>search[:id]]
      if rec_sec
        rec_sec.update(:file_id=>file_id)
      end
    end
  end


  # Create a file on system. Add the uploaded file to
  # basedir, and creates a {IFile} object
  # @param basedir Base directory for files
  # @param file_uploaded as rack uploaded file
  # @param filename, as wanted on the system
  # @param filetypem as provided by mime types
  # @return file_id Id attribute from {IFile} object

  def create_file_on_system
    sha256 = Digest::SHA256.file(@filepath).hexdigest
    archivo_o = IFile.where(:sha256 => sha256)
    if archivo_o.empty?
      file_path_new = "#{sha256[0]}/#{filename}"
      ruta_completa = "#{basedir}/#{file_path_new}"
      FileUtils.mkdir_p File.dirname(ruta_completa) unless File.exist?(File.dirname(ruta_completa))
      FileUtils.cp filepath, ruta_completa
      @file_id = IFile.insert(:filetype => filetype, :filename => filename, :file_path => file_path_new, :sha256 => sha256)
    else
      @file_id = archivo_o.first[:id]
    end
    @file_id
  end
private :create_file_on_system
end

