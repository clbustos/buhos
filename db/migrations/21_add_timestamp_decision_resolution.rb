Sequel.migration do
  up do
    alter_table(:allocation_cds) do
      add_column :timestamp, DateTime
    end
    alter_table(:decisions) do
      add_column :timestamp, DateTime
    end
    alter_table(:resolutions)   do
      add_column :timestamp, DateTime
    end
  end

  down do
    alter_table(:allocation_cds) do
      drop_column :timestamp
    end

    alter_table(:decisions) do
      drop_column :timestamp
    end
    alter_table(:resolutions) do
      drop_column :timestamp
    end
  end

end