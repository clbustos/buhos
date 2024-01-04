# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2024, Claudio Bustos Navarrete
# All rights reserved.
# Licensed BSD 3-Clause License
# See LICENSE file for more information

#@!scale scales routes

# Display list of scales
get '/admin/scales' do
  halt_unless_auth('scale_admin')
  @scales=Scale.all
  haml :scales, escape_html: false
end

# Display form to edit a scale

=begin
get "/scale/:id/edit" do |id|
  halt_unless_auth('scale_admin')
  @scale=Scale[id]
  haml %s{scales/edit}
end

# Display form to create a new scale

get '/scale/new' do
  halt_unless_auth('scale_admin')
  @scale={:id=>"NA",:description=>""}

  haml %s{scales/edit}
end

# Display information for a scale
get "/scale/:id" do |id|
  halt_unless_auth('scale_admin')
  @scale=scale[id]
  haml %s{scales/view}
end

# Updates information for a scale
post '/scale/update' do
  halt_unless_auth('scale_admin')

  id=params['scale_id']
  name=params['name']

  if name.chomp==""
    add_message(t(:Scale_without_name), :error)
    redirect back
  end
  description=params['description']

  if id=="NA"
    scale=scale.create(:name=>name,:description=>description)
    id=scale.id
  else
    scale[id].update(:name=>name,:description=>description)
  end
  redirect url('/admin/scales')
end
=end


#@!endscale