class BibliographicDatabase < Sequel::Model
  def self.name_a_id_h
    $db['SELECT * FROM bibliographic_databases'].as_hash(:name, :id)
  end
  def self.id_a_name_h
    $db['SELECT * FROM bibliographic_databases'].as_hash(:id, :name)
  end
end
