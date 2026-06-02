Sequel.migration do
  up do
    alter_table(:criteria) do
      set_column_type :text, String, :text=>true
    end

    alter_table(:quality_criteria) do
      set_column_type :text, String, :text=>true, :null=>false
    end
  end

  down do
    alter_table(:criteria) do
      set_column_type :text, String
    end

    alter_table(:quality_criteria) do
      set_column_type :text, String, :null=>false
    end
  end
end
