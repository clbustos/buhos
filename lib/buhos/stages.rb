module Buhos
  # Stages ids, names, and methods to access them
  module Stages
    IDS=[:search,
            :screening_title_abstract,
            :screening_references,
            :review_full_text,
            #:analisis,
            :report
    ]

    NAMES={:search=> "stage.search",
                 :screening_title_abstract=> "stage.screening_title_abstract",
                 :screening_references => "stage.screening_references",
                 :review_full_text=> "stage.review_full_text",
                 #:analisis => "stage.analysis",
                 :report=> "stage.report"}

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
  end
end

