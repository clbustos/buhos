Sequel.migration do
  change do
    alter_table(:systematic_reviews) do
      add_column :expected_reviewers_screening, Integer, :default=>2, :null=>false
      add_column :expected_reviewers_snowball, Integer, :default=>2, :null=>false
      add_column :expected_reviewers_full_text, Integer, :default=>2, :null=>false
      add_column :expected_reviewers_extraction, Integer, :default=>2, :null=>false
    end
  end
end
