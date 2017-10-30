require_relative 'revision_sistematica'
require_relative 'seguridad'
require_relative 'canonico_documento'


class Asignacion_Cd < Sequel::Model
  many_to_one :revision_sistematica, :class=>Revision_Sistematica
  many_to_one :usuario             , :class=>Usuario
  many_to_one :canonico_documento  , :class=>Canonico_Documento

end