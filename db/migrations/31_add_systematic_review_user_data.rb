Sequel.migration do
  change do
    create_table(:systematic_review_user_data) do
      primary_key :id
      foreign_key :user_id, :users, null: false, on_delete: :cascade
      foreign_key :systematic_review_id, :systematic_reviews, null: false, on_delete: :cascade
      TrueClass :invitation_sent, default: false, null: false
      Integer :dashboard_order, default: 0, null: false

      index [:user_id, :systematic_review_id], unique: true, name: :sr_user_data_unique_pair
      index :systematic_review_id
    end
  end
end
