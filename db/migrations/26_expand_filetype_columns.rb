# MIME types can be longer than 50 characters.
Sequel.migration do
  change do
    alter_table(:files) do
      set_column_type :filetype, String, :size=>255
    end

    alter_table(:searches) do
      set_column_type :filetype, String, :size=>255
    end
  end
end
