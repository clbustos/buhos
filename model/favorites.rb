class FavoriteGroup < Sequel::Model
  plugin :validation_helpers
  # Relaciones
  many_to_one :user
  one_to_many :favorite_documents, key: :group_id

  # Validaciones
  def validate
    super
    validates_presence [:name, :user_id]
    validates_unique([:user_id, :name], message: "Ya tienes un grupo con ese nombre")
  end

  # Helper para saber si es privado
  def private?
    !is_public
  end
end


class FavoriteDocument < Sequel::Model
  plugin :validation_helpers
  # Necesario para claves primarias compuestas en Sequel
  unrestrict_primary_key

  # Relaciones
  many_to_one :user
  many_to_one :canonical_document
  many_to_one :favorite_group, key: :group_id

  def validate
    super
    validates_presence [:canonical_document_id, :user_id]
  end

  # Helper para obtener el título del documento directamente
  def title
    canonical_document.title
  end
end

