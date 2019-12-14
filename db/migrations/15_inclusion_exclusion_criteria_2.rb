Sequel.migration do
  up do
    alter_table(:cd_criteria) do
      add_column :presence, String
    end
    from(:cd_criteria).where(selected:'0').update(presence:'present')
    from(:cd_criteria).where(selected:'1').update(presence:'absent')
    alter_table(:cd_criteria) do
      drop_column :selected
    end
  end

  down do
    alter_table(:cd_criteria) do
      add_column :selected, String
    end
    from(:cd_criteria).where(presence:'present').update(selected:'1')
    from(:cd_criteria).where(presence:'absent' ).update(selected:'0')
    alter_table(:cd_criteria) do
      drop_column :presence
    end
  end
end