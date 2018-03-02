Sequel.migration do
  change do
    alter_table(:systematic_reviews) do
      # Mïnimo número de references rtr para revisión de references
      add_column :n_min_rr_rtr, Integer, default: 2
    end
  end
end