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

#
module Buhos
  # Stages ids, names, and methods to access them
  module Stages
    STAGE_SEARCH=:search
    STAGE_SCREENING_TITLE_ABSTRACT=:screening_title_abstract
    STAGE_SCREENING_REFERENCES=:screening_references
    STAGE_REVIEW_FULL_TEXT=:review_full_text
    STAGE_REPORT=:report
    IDS=[STAGE_SEARCH,
            STAGE_SCREENING_TITLE_ABSTRACT,
            STAGE_SCREENING_REFERENCES,
            STAGE_REVIEW_FULL_TEXT,
            #:analysis,
            STAGE_REPORT
    ].freeze

    NAMES={STAGE_SEARCH=> "stage.search",
           STAGE_SCREENING_TITLE_ABSTRACT=> "stage.screening_title_abstract",
           STAGE_SCREENING_REFERENCES=> "stage.screening_references",
           STAGE_REVIEW_FULL_TEXT=> "stage.review_full_text",
                 #:analysis => "stage.analysis",
           STAGE_REPORT=> "stage.report"}.freeze

    def self.get_stage_name(stage)
      NAMES[stage.to_sym]
    end
  end

  module StagesMixin
    def get_stage_name(stage)
      Buhos::Stages.get_stage_name(stage)
    end
    def get_stages_ids
      Buhos::Stages::IDS
    end
    def get_stages_names
      Buhos::Stages::NAMES
    end
    def get_stages_names_t
      Buhos::Stages::NAMES.inject({}) {|ac,v|  ac[v[0]]=I18n.t(v[1]);ac  }
    end
  end
end

