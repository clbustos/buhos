# Added support for e-mail, institution and security events
Sequel.migration do
  up do
    create_table(:institutions) do
       primary_key :id
       String :name
    end

    create_table(:security_events) do
      primary_key :id
      DateTime :timestamp
      String :event_type
      String :source_ip
      String :affected_resource
      foreign_key :user_id, :users, :null=>true, :key=>[:id]
      String :event_description, :text=>true
      String :outcome_result
      String :severity_level
      String :event_source
      String :location
      String :additional_context, :text=>true
    end

    alter_table(:users) do
      add_column :email, String
      add_column :token_password,String, :size=>255
      add_column :token_datetime, DateTime
      add_foreign_key :institution_id, :institutions, :key=>[:id]
    end
  end

  down do
   alter_table(:users) do
      drop_column :email
      drop_column :token_password
      drop_column :token_datetime
      drop_column :institution_id
   end
   drop_table :institutions
   drop_table :security_events
  end

end