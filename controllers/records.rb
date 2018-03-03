# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2018, Claudio Bustos Navarrete
# All rights reserved.
# Licensed BSD 3-Clause License
# See LICENSE file for more information


# @!group Records

# View a record
get '/record/:id' do |id|
  halt_unless_auth('record_view')
  @reg=Record[id]
  @references=@reg.references
  haml "record".to_sym
end

# Query crossref for a given record
get '/record/:id/search_crossref' do |id|
  halt_unless_auth('record_edit')

  @reg=Record[id]
  @respuesta=@reg.crossref_query
  # #$log.info(@respuesta)
  haml "systematic_reviews/record_search_crossref".to_sym
end

# Assign a DOI to a record
get '/record/:id/assign_doi/:doi' do |id,doi|
  halt_unless_auth('record_edit')
  $db.transaction(:rollback=>:reraise) do
    @reg=Record[id]
    doi=doi.gsub("***","/")
    result=@reg.add_doi(doi)
    add_result(result)
  end
  redirect back
end

# Add manual references to a record
post '/record/:id/manual_references' do |id|
  halt_unless_auth('record_edit')
  ref_man=params['reference_manual']
  $db.transaction(:rollback => :reraise) do
    if ref_man
      partes=ref_man.split("\n").map {|v| v.strip.gsub("[ Links ]", "").gsub(/\s+/, ' ')}.find_all {|v| v!=""}
      partes.each do |parte|
        ref=Reference.get_by_text_and_doi(parte, nil, true)
        ref_reg=RecordsReference.where(:record_id => id, :reference_id => ref[:id]).first
        unless ref_reg
          RecordsReference.insert(:record_id => id, :reference_id => ref[:id])
        end
      end
      add_message(::I18n.t(:Added_references_to_record, :record_id=>id, :count_references=>partes.length))
    end
  end
  redirect back
end


# @!endgroup