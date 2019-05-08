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

  raise Buhos::NoRecordIdError, id if !@reg

  @references=@reg.references
  haml "record".to_sym
end

# Query crossref for a given record
get '/record/:id/search_crossref' do |id|
  halt_unless_auth('record_edit')

  @reg=Record[id]

  raise Buhos::NoRecordIdError, id if !@reg

  @response_crossref=@reg.crossref_query

  #$log.info(@respuesta)
  haml "systematic_reviews/record_search_crossref".to_sym
end

# Assign a DOI to a record
get '/record/:id/assign_doi/:doi' do |id,doi|
  halt_unless_auth('record_edit')

  @reg=Record[id]
  raise Buhos::NoRecordIdError, id if !@reg

  $db.transaction(:rollback=>:reraise) do
    doi=doi.gsub("***","/")
    result=@reg.add_doi(doi)
    add_result(result)
  end
  redirect back
end


# Reference action
#
post '/record/:id/references_action' do |id|
  halt_unless_auth('reference_edit')
  record=Record[id]
  raise Buhos::NoRecordIdError, id if record.nil?
  action=params['action']
  references=params['references']
  if action=='delete'
    if references
      $db.transaction do
        rr=RecordsReferences.where(:record_id=>id, :reference_id=>references)
        count=rr.count
        rr.delete
        add_message(t(:Count_references_delete, count:count))
      end
    else
      add_message(t(:No_references_selected), :error)
    end
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
        parte=parte.chomp.lstrip
        ref=Reference.get_by_text_and_doi(parte, nil, true)
        ref_reg=RecordsReferences.where(:record_id => id, :reference_id => ref[:id]).first
        unless ref_reg
          RecordsReferences.insert(:record_id => id, :reference_id => ref[:id])
        end
      end
      add_message(::I18n.t(:Added_references_to_record, :record_id=>id, :count_references=>partes.length))
    end
  end
  redirect back
end


# @!endgroup