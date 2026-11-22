Sequel.migration do
  up do
    roles={'independent_researcher'=>'Independent researcher', 'review_collaborator'=>'Review collaborator'}
    roles.each {|id, description| from(:roles).insert(id: id, description: description)}
    %w[review_view group_view].each do |permission|
      from(:authorizations).insert(id: permission) unless from(:authorizations)[id: permission]
      roles.each_key {|role_id| from(:authorizations_roles).insert(role_id: role_id, authorization_id: permission)}
    end
  end
end
