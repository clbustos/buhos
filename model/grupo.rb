require_relative 'usuario'
class Grupo < Sequel::Model
  many_to_many :usuarios
  many_to_one :administrador, :class => Usuario, :key => :administrador_grupo
end
