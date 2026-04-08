# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2025, Claudio Bustos Navarrete
# All rights reserved.
# Licensed BSD 3-Clause License
# See LICENSE file for more information

# @!group reflection

# Get all routes on system

get '/admin/routes' do
  halt_unless_auth('reflection')
  lines = Buhos::Reflection.get_routes(self)
    "<html><body>#{lines.sort.join('<br/>')}</body></html>"

end


# Get all authorizations used on system



# @!endgroup