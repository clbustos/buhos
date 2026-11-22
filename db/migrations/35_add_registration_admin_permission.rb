Sequel.migration do
  up do
    permission={id: 'registration_admin'}
    from(:authorizations).insert(permission) unless from(:authorizations)[permission]
    grant={role_id: 'administrator', authorization_id: permission[:id]}
    if from(:roles)[id: 'administrator'] && !from(:authorizations_roles)[grant]
      from(:authorizations_roles).insert(grant)
    end
  end
end
