Sequel.migration do
  change do
    create_table(:invitations) do
      primary_key :id
      String :name, null: false
      String :email, null: false
      String :decision, default: 'pending', null: false
      String :token, size: 64, null: false, unique: true
      String :language, default: 'es', null: false
      TrueClass :email_sent, default: false, null: false
      foreign_key :systematic_review_id, :systematic_reviews, null: false, on_delete: :cascade
      foreign_key :sender_id, :users, null: false
      foreign_key :user_id, :users
      index [:systematic_review_id, :email], unique: true
    end
  end
end
