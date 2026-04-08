# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2025, Claudio Bustos Navarrete
# All rights reserved.
# Licensed BSD 3-Clause License
# See LICENSE file for more information

# @!group permissions
require_relative '../../lib/buhos/create_schema.rb'
# List of roles
get '/admin/authorizations' do
  halt_unless_auth('reflection')

  @authorizations=Authorization.order(:id)

  auth=Buhos::Reflection.get_authorizations(self)
  @files=auth.files
  @permits=auth.permits
  haml "admin/permits".to_sym, escape_html: false

end

get '/admin/authorizations/renew' do
  halt_unless_auth('reflection')

  ::Buhos::SchemaCreation.create_authorizations($db)
  ::Buhos::SchemaCreation.allocate_authorizations_to_roles($db)

  add_message(t(:Authorizations_renewed))
  redirect back
end

# Form to create a new role



# @!endgroup