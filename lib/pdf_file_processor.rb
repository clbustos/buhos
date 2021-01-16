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

# Process a pdf file. Obtains information and create all necessary dependence to it

class PdfFileProcessor
  # @param filepath
  include Buhos::Helpers
  attr_reader :results
  attr_reader :dir_files
  attr_reader :title
  attr_reader :doi
  attr_reader :author
  attr_reader :canonical_document
  attr_reader :uid
  def initialize(search, filepath, dir_files)
    @search=search
    @filepath=filepath
    @dir_files=dir_files
    @results=Result.new
    @author=nil
    @title=nil
    @doi=nil
    @new_cd=nil
  end
  def systematic_review
    @search.systematic_review
  end
  def search_id
    @search.id
  end

  def bb_general_id
    BibliographicDatabase[:name=>'generic'][:id]
  end

  def get_record_by_uid(uid)
    record=Record.where(:uid=>uid).first
    if !record
      record_id=Record.insert(:uid=>uid,:author=>author, :title=>title,:type=>"tempfile",:year=>0,:doi=>doi, :bibliographic_database_id=>bb_general_id)
      record=Record[record_id]
    end
    record
  end

  def create_record_search_by_ids(record_id, search_id)
    #$log.info Record.all
    #$log.info Search.all
    unless RecordsSearch[:record_id=>record_id, :search_id=>search_id]
      RecordsSearch.insert(:record_id=>record_id, :search_id=>search_id)
    end
  end
  def simulate_file_uploaded
    {
        filename: File.basename(@filepath),
        type: "application/pdf",
        tempfile: @filepath
    }
  end

  def get_canonical_document(record)
    @new_cd=false
    if record[:canonical_document_id]

      @canonical_document=CanonicalDocument[record[:canonical_document_id]]
    else
      if record[:doi].to_s =~ /10\./
        @canonical_document = CanonicalDocument[:doi => record[:doi]]
      end

      if @canonical_document.nil?
        @new_cd=true
        can_doc_id = CanonicalDocument.insert(:title=>title,:type=>"tempfile",:year=>0,:doi=>doi, :author=>author)
        @canonical_document = CanonicalDocument[:id => can_doc_id]
      end
      record.update(:canonical_document_id=>@canonical_document[:id])

    end
    @canonical_document
  end


  def uid
    if doi
      "doi:#{doi}"

    else
      sha256 = Digest::SHA256.file(@filepath).hexdigest
      "file:#{sha256}"
    end
  end

  def process
    pdfp=PdfProcessor.new(@filepath)

      @doi=pdfp.get_doi
      @author=pdfp.author ? protect_encoding(pdfp.author) : ""
      @title=pdfp.title ? protect_encoding(pdfp.title) : ""

      #@author=I18n::t(:Unknown_author) if author==""
      #@title=I18n::t(:Unknown_title) if title==""



      record=get_record_by_uid(uid)
      $log.info(record)

      # Recuperamos información desde crossref


      create_record_search_by_ids(record.id, search_id)
      cd=get_canonical_document(record)
        $log.info(cd)
      file_proc=FileProcessor.new(simulate_file_uploaded, dir_files)
      file_proc.add_to_sr(systematic_review)
      file_proc.add_to_cd(cd)
      file_proc.add_to_record_search(@search, record)
      @results.success(I18n::t("search.successful_upload", filename:File.basename(@filepath), sr_name:systematic_review.name))
      # Add crossref information
      @results.add_result(record.add_doi_automatic)
      if record.doi
        #$log.info("File:#{@filepath} with doi")
        @results.add_result(record.references_automatic_crossref)
        @results.add_result(record.update_info_using_crossref)
        cd.update_info_using_record(record) if @new_cd
      end
    end

end

