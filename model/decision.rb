require_relative 'usuario'
require_relative 'canonico_documento'
require_relative 'revision_sistematica'

class Decision < Sequel::Model
  NO_DECISION='ND'
  N_EST={
      "yes" => :Yes,
      "no" => :No,
      "undecided" => :Undecided,
      Decision::NO_DECISION =>  :Without_decision,

  }


  def self.get_name_decision(x)
    x.nil?  ? N_EST[NO_DECISION] :N_EST[x]
  end
end

