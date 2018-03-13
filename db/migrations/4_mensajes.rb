# Agrega asignaciones de documentos canónicos a users.
# Debería hacerse después de la selección por abstract y references...

Sequel.migration do
  change do
    create_table(:messages) do
      # Mïnimo número de references rtr para revisión de references
      primary_key :id
      foreign_key :user_from, :users, :null=>false, :key=>[:id]
      foreign_key :user_to, :users, :null=>false, :key=>[:id]
      foreign_key :reply_to,   :messages, :null=>true, :key=>[:id]
      DateTime :time
      String :subject
      String :text, :text=>true
      Bool :viewed
      index [:user_from]
      index [:user_to]
    end
    create_table(:message_srs) do
      primary_key :id
      foreign_key :systematic_review_id, :systematic_reviews, :null=>false, :key=>[:id]
      foreign_key :user_from, :users, :null=>false, :key=>[:id]
      foreign_key :reply_to,  :message_srs, :null=>true, :key=>[:id]
      DateTime :time
      String :subject
      String :text, :text=>true
    end
    create_table(:message_sr_seens) do
      foreign_key :m_rs_id,   :message_srs, :null=>false, :key=>[:id]
      foreign_key :user_id, :users, :null=>false, :key=>[:id]
      Bool :viewed
      primary_key [:m_rs_id, :user_id]
    end
  end
end