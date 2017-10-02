Sequel.migration do
  change do
    alter_table(:revisiones_sistematicas) do
      # Mïnimo número de referencias rtr para revisión de referencias
      add_column :n_min_rr_rtr, Integer, default: 2
    end
  end
end