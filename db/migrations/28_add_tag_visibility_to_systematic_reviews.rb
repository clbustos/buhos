Sequel.migration do
  up do
    alter_table(:systematic_reviews) do
      add_column :show_other_users_tags, TrueClass, :default=>true, :null=>false
    end
  end

  down do
    alter_table(:systematic_reviews) do
      drop_column :show_other_users_tags
    end
  end
end
