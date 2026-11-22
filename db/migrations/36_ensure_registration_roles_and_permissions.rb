Sequel.migration do
  up do
    roles={
      'administrator'=>['App administrator', %w[registration_admin]],
      'independent_researcher'=>['Independent researcher', %w[review_view group_view]],
      'review_collaborator'=>['Review collaborator', %w[review_view group_view]]
    }
    roles.each do |role_id, (description, permissions)|
      from(:roles).insert(id: role_id, description: description) unless from(:roles)[id: role_id]
      permissions.each do |permission|
        from(:authorizations).insert(id: permission) unless from(:authorizations)[id: permission]
        grant={role_id: role_id, authorization_id: permission}
        from(:authorizations_roles).insert(grant) unless from(:authorizations_roles)[grant]
      end
    end
  end
end
