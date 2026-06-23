Sequel.migration do
  up do
    alter_table(:systematic_reviews) do
      add_column :blind_reference_screening, TrueClass, :default=>false, :null=>false
    end
  end

  down do
    alter_table(:systematic_reviews) do
      drop_column :blind_reference_screening
    end
  end
end
