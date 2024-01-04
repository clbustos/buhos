# Copyright (c) 2016-2024, Claudio Bustos Navarrete
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
module Buhos
  # Delegation pattern for Sequel::Database
  # Used on spec to change the database between tests
  class DBAdapter
    attr_accessor :logger
    def initialize
      @current=nil
    end
    def current
      @current
    end
    def use_db(db)
      @current=db
      db.loggers << @logger
    end
    # This is ugly. I know.
    # I just do it to allow testing
    def update_model_association
      ::IFile.dataset=self[:files]
      ::FileCd.dataset=self[:file_cds]
      ::FileSr.dataset=self[:file_srs]
      ::AllocationCd.dataset=self[:allocation_cds]
      ::BibliographicDatabase.dataset=self[:bibliographic_databases]
      ::Search.dataset=self[:searches]


      ::CanonicalDocument.dataset=self[:canonical_documents]
      ::CrossrefDoi.dataset=self[:crossref_dois]
      ::CrossrefQuery.dataset=self[:crossref_queries]
      ::Decision.dataset=self[:decisions]
      ::Group.dataset=self[:groups]
      ::Message.dataset=self[:messages]
      ::MessageSr.dataset=self[:message_srs]
      ::MessageSrSeen.dataset=self[:message_sr_seens]
      ::Reference.dataset=self[:bib_references]
      ::RecordsReferences.dataset=self[:records_references]
      ::Resolution.dataset=self[:resolutions]
      ::Record.dataset=self[:records]
      ::RecordsSearch.dataset=self[:records_searches]
      ::Tag.dataset=self[:tags]
      ::T_Class.dataset=self[:t_classes]
      ::TagInClass.dataset=self[:tag_in_classes]
      ::TagInCd.dataset=self[:tag_in_cds]
      ::TagBwCd.dataset=self[:tag_bw_cds]
      ::SystematicReview.dataset=self[:systematic_reviews]
      ::SrField.dataset=self[:sr_fields]
      ::SrTaxonomy.dataset=self[:sr_taxonomies]
      ::SrTaxonomyCategory.dataset=self[:sr_taxonomy_categories]
      ::Systematic_Review_SRTC.dataset=self[:systematic_review_srtcs]

      ::User.dataset=self[:users]
      ::Authorization.dataset=self[:authorizations]
      ::Role.dataset=self[:roles]
      ::Scopus_Abstract.dataset=self[:scopus_abstracts]
      ::Group.dataset=self[:groups]
      ::GroupsUser.dataset=self[:groups_users]
      ::AuthorizationsRole.dataset=self[:authorizations_roles]

      ::Criterion.dataset=self[:criteria]
      ::SrCriterion.dataset=self[:sr_criteria]
      ::CdCriterion.dataset=self[:cd_criteria]

      ::Criterion.dataset=self[:criteria]

      ::QualityCriterion.dataset=self[:quality_criteria]
      ::SrQualityCriterion.dataset=self[:sr_quality_criteria]
      ::CdQualityCriterion.dataset=self[:cd_quality_criteria]
      ::Scale.dataset=self[:scales]


      ::Pmc_Summary.dataset=self[:pmc_summaries]

      ::Search.many_to_many :records, :class=>Record


      ::Record.many_to_one :canonical_document, :class=>CanonicalDocument

      ::Reference.many_to_many :records
      ::SystematicReview.many_to_one :group
      ::SystematicReview.one_to_many :message_srs, :class=>MessageSr


      ::QualityCriterion

      ::Group.many_to_many :users
    end
    def method_missing(m, *args, &block)
      #puts "#{m}: #{args}"
      @current.send(m, *args, &block)
      #puts "There's no method called #{m} here -- please try again."
    end
    def self.method_missing(m, *args, &block)
      raise "Can't handle this"
    end
  end
end