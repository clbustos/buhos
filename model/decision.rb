require_relative 'usuario'
require_relative 'canonico_documento'
require_relative 'revision_sistematica'

class Decision < Sequel::Model

  N_EST={
      "--" => "Sin decisión",
      "yes" => "Sí",
      "no" => "No",
      "undecided" => "Indeciso"
  }


  def self.get_name_decision(x)
    x.nil?  ? N_EST['--'] :N_EST[x]
  end
end

