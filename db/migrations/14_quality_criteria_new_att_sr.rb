Sequel.migration do

  up do

    alter_table(:systematic_reviews) do
      add_column :research_questions, String, :text=>true
      add_column :conflict_of_interest, String, :text=>true
    end


    create_table(:scales) do
      primary_key :id
      String :name, :null=>false
      String :description, :null=>false, :default=>''
    end

    create_table(:scales_items) do
      foreign_key :scale_id,                 :scales,                     :null=>false, :key=>[:id], :default=>nil
      Integer     :value,                                                 :null=>false
      String      :name,                                                  :null=>false
      primary_key [:scale_id, :value]
    end


    create_table(:quality_criteria) do
      primary_key :id
      String :text, :null=>false

    end


    create_table(:sr_quality_criteria) do
      #Integer :quality_criterion_id
      foreign_key :quality_criterion_id,    :quality_criteria,            :null => false, :key=> [:id]
      #Integer :systematic_review_id
      foreign_key :systematic_review_id,    :systematic_reviews,          :null=>false, :key=>[:id]
      foreign_key :scale_id,                :scales,                      :null => false, :key=> [:id]
      Integer     :order,                                              :null => false, :default=>0
      primary_key [:systematic_review_id, :quality_criterion_id]
    end

     create_table(:cd_quality_criteria) do
       foreign_key :quality_criterion_id,    :quality_criteria,            :null => false, :key=> [:id]
       foreign_key :canonical_document_id,   :canonical_documents,         :null => false, :key=> [:id]
       foreign_key :user_id,                 :users,                       :null => false, :key=> [:id]
       foreign_key :systematic_review_id,    :systematic_reviews,          :null => false, :key=> [:id]
       Integer     :scale_id,                                              :null => false
       Integer     :value,                                                 :null => false

       foreign_key [:scale_id, :value], :scales_items

       String      :commentary,              :text=>true
       primary_key [:quality_criterion_id, :canonical_document_id, :user_id, :systematic_review_id]
     end

  end

  down do
    from(:scales_items).delete
    from(:scales).delete
    drop_table(:cd_quality_criteria)
    drop_table(:sr_quality_criteria)
    drop_table(:quality_criteria)
    drop_table(:scales_items)
    drop_table(:scales)

    alter_table(:systematic_reviews) do
      drop_column :research_questions
      drop_column :conflict_of_interest
    end

  end
end