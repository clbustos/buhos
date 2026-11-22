Sequel.migration do
  up do
    roles={'independent_researcher'=>'Independent researcher', 'review_collaborator'=>'Review collaborator'}
    roles.each do |id, description|
      from(:roles).insert(id: id, description: description) unless from(:roles)[id: id]
    end
    %w[review_view group_view].each do |permission|
      from(:authorizations).insert(id: permission) unless from(:authorizations)[id: permission]
      roles.each_key do |role_id|
        grant={role_id: role_id, authorization_id: permission}
        from(:authorizations_roles).insert(grant) unless from(:authorizations_roles)[grant]
      end
    end
  end
end
