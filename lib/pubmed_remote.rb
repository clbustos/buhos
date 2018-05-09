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

require_relative 'pmc'

module PubmedRemote
  # Update Canonical documents with pmid
  # @param cd_cd a Sequel Dataset
  # @return Result
  def self.retrieve_pmid(cd_ds)
    dois_list=cd_ds.map(:doi)
    dtpp=PMC::DoiToPmidProcessor.new(dois_list)
    dtpp.process
    retrieved_dois=dtpp.doi_as_pmid.find_all {|v| !v[1].nil?}
    nil_dois=dtpp.doi_as_pmid.find_all {|v| v[1].nil?}
    bad_dois=dtpp.doi_bad
    $db.transaction(:rollback=>:reraise) do
      retrieved_dois.each do |doi_pmid|
        CanonicalDocument.where(:doi=>doi_pmid[0]).update(:pmid=>doi_pmid[1])
      end
    end
    result=Result.new
    result.success(I18n::t("pubmedremote.retrieve_pmid_result", nil_dois:nil_dois.count, dois_pmid:retrieved_dois.count))
    if(bad_dois.length>0)
      result.error(I18n::t("pubmedremote.retrieve_pmid_result_bad_dois", bad_dois:bad_dois.join(", ")))
    end
  result
  end

  def self.reference_integrator_xml(pmid)
    co=self.process_single_pmid(pmid)
    if(co)
      BibliographicalImporter::PmcEfetchXml::Reader.parse(co)[0]
    else
      false
    end
  end
  # Process a single pmid
  def self.process_single_pmid(pmid)
    pmc_summary=Pmc_Summary[pmid]

    if !pmc_summary
      efetch=PMC::Efetch.new([pmid])
      efetch.process
      xml=efetch.pmid_xml.first.xpath("//PubmedArticle").to_s
      Pmc_Summary.insert(:id=>pmid, :xml=>xml)
      xml
    else
      pmc_summary.xml
    end
  end
end