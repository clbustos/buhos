Sequel.migration do
  change do
    create_table(:registration_requests) do
      primary_key :id
      String :name, null: false
      String :login, null: false
      String :email, null: false
      String :language, size: 2, null: false
      String :status, size: 16, null: false, default: 'pending'
      TrueClass :pending, default: true
      DateTime :created_at, null: false
      DateTime :notified_at
      foreign_key :user_id, :users, on_delete: :set_null
      index [:login, :pending], unique: true
      index [:email, :pending], unique: true
    end
  end
end
