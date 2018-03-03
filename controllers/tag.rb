# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2018, Claudio Bustos Navarrete
# All rights reserved.
# Licensed BSD 3-Clause License
# See LICENSE file for more information

post '/tags/classes/new' do
  halt_unless_auth('tag_edit')
  @review=SystematicReview[params['review_id']]
  stage=  params['stage']
  stage=nil if stage=="NIL"
  type =  params['type']
  return 404 if @review.nil?

  $db.transaction(:rollback=>:reraise) do
    T_Class.insert(:name=>params["name"],
                   :systematic_review_id=>@review.id,
                   :stage=>stage,
                   :type=>type)
  end
  redirect back
end


put '/tags/classes/edit_field/:field' do |field|
  halt_unless_auth('tag_edit')

  pk = params['pk']
  value = params['value']
  value = nil if value=="NIL"
  return 405 unless %w{name stage type}.include? field
  T_Class[pk].update(field.to_sym=>value)
  return 200
end


put "/tag/edit" do
  halt_unless_auth('tag_edit')

  pk = params['pk']
  value = params['value'].chomp
  return [405,"Debe ingresar algun text"] if value==""
  Tag[pk].update(:text=>value)
  return 200
end

post '/tags/class/:t_clase_id/add_tag' do |t_clase_id|
  halt_unless_auth('tag_edit')

  t_class=T_Class[t_clase_id]
  raise  NoTagClassIdError, t_clase_id if !t_class
  tag_name=params['value'].chomp
  return 405 if tag_name==""
  tag=Tag.get_tag(tag_name)
  t_class.allocate_tag(tag)
  partial("tags/tags_class", :locals=>{t_class: t_class})
end


post '/tags/class/:t_clase_id/remove_tag' do |t_clase_id|
  halt_unless_auth('tag_edit')
  t_class=T_Class[t_clase_id]
  raise  NoTagClassIdError, t_clase_id if !t_class

  tag=Tag[params['value']]
  raise  NoTagIdError, value  if !tag

  t_class.deallocate_tag(tag)

  partial("tags/tags_class", :locals=>{t_class: t_class})
end

get '/tag/:tag_id/rs/:rs_id/stage/:stage/cds' do |tag_id, rs_id, stage|
  halt_unless_auth('review_view')

  @tag=Tag[tag_id]
  raise Buhos::NoTagIdError, tag_id if !@tag
  @review=SystematicReview[rs_id]

  @ars=AnalysisSystematicReview.new(@review)

  @usuario=User[session['user_id']]
  return 404 if @tag.nil? or @review.nil?
  @stage=stage
  @cds_tag=TagInCd.cds_rs_tag(@review,@tag,false,stage)
  @cds=CanonicalDocument.where(:id=>@cds_tag.map(:id))
  haml '/tags/rs_cds'.to_sym
end


get '/tag/:tag_id/rs/:rs_id/cds' do |tag_id, rs_id|
  halt_unless_auth('review_view')
  @tag=Tag[tag_id]
  raise Buhos::NoTagIdError, tag_id if !@tag

  @review=SystematicReview[rs_id]

  @ars=AnalysisSystematicReview.new(@review)

  @usuario=User[session['user_id']]
  return 404 if @tag.nil? or @review.nil?

  @cds_tag=TagInCd.cds_rs_tag(@review,@tag)
  @cds=CanonicalDocument.where(:id=>@cds_tag.map(:id))
  haml '/tags/rs_cds'.to_sym
end






post '/tags/cd/:cd_id/rs/:rs_id/:accion' do |cd_id,rs_id,accion|
  halt_unless_auth('review_analyze')
  cd=CanonicalDocument[cd_id]
  rs=SystematicReview[rs_id]
  return 405 if cd.nil? or rs.nil?

  user_id=session['user_id']
  if accion=='add_tag'
    tag_name=params['value'].chomp
    return 405 if tag_name==""
    tag=Tag.get_tag(tag_name)
    $db.transaction(:rollback=>:reraise) do
      TagInCd.approve_tag(cd,rs,tag,user_id)
    end
  elsif accion=='approve_tag'
    tag_id=params['tag_id']
    tag=Tag[tag_id]
    return 404 if tag.nil?
    $db.transaction(:rollback=>:reraise) do
      TagInCd.approve_tag(cd,rs,tag,user_id)
    end
  elsif accion=='reject_tag'
    tag_id=params['tag_id']
    tag=Tag[tag_id]
    return 404 if tag.nil?
    $db.transaction(:rollback=>:reraise) do
      TagInCd.reject_tag(cd,rs,tag,user_id)
    end
  else
    return [405,"I don't know the action to perform"]
  end

  partial("tags/tags_cd_rs", :locals=>{cd:cd, review:rs, :nuevo=>true, user_id: user_id})
end



post '/tags/cd_start/:cd_start_id/cd_end/:cd_end_id/rs/:rs_id/:accion' do |cd_start_id,cd_end_id,rs_id,accion|
  halt_unless_auth('review_analyze')
  cd_start=CanonicalDocument[cd_start_id]
  cd_end=CanonicalDocument[cd_end_id]
  rs=SystematicReview[rs_id]
  return 405 if cd_start.nil? or cd_end.nil? or rs.nil?

  user_id = session['user_id']

  if accion=='add_tag'
    tag_name=params['value'].chomp
    return 405 if tag_name==""
    tag=Tag.get_tag(tag_name)
    $db.transaction(:rollback=>:reraise) do
      TagBwCd.approve_tag(cd_start,cd_end,rs,tag,user_id)
    end
  elsif accion=='approve_tag'
    tag_id=params['tag_id']
    tag=Tag[tag_id]
    return 404 if tag.nil?
    $db.transaction(:rollback=>:reraise) do
      TagBwCd.approve_tag(cd_start,cd_end,rs,tag,user_id)
    end
  elsif accion=='reject_tag'
    tag_id=params['tag_id']
    tag=Tag[tag_id]
    return 404 if tag.nil?
    $db.transaction(:rollback=>:reraise) do
      TagBwCd.reject_tag(cd_start,cd_end,rs,tag,user_id)
    end
  else
    return [405,"I don't know the action to perform"]
  end

  partial("tags/tags_cd_rs_ref", :locals=>{cd_start: cd_start, cd_end:cd_end, review:rs, :nuevo=>true, user_id: user_id})
end



get '/tags/basic_10.json' do
  halt_unless_auth('review_view')
  require 'json'
  content_type :json
  Tag.order(:text).limit(10).map {|v|
    {id:v[:id],
     value:v[:text],
     tokens:v[:text].split(/\s+/)
    }
  }.to_json
end


get '/tags/basic_ref_10.json' do
  halt_unless_auth('review_view')
  require 'json'
  content_type :json
  Tag.order(:text).limit(10).map {|v|
    {id:v[:id],
     value:v[:text],
     tokens:v[:text].split(/\s+/)
    }
  }.to_json
end

get '/tags/query_json/:query' do |query|
  halt_unless_auth('review_view')
  require 'json'
  content_type :json

  res=$db["SELECT id, text,COUNT(*) as n from tags t INNER JOIN tag_in_cds tec ON t.id=tec.tag_id WHERE INSTR(text,?)>0 and decision='yes' GROUP BY t.text ORDER BY n DESC LIMIT 10", query]
  res.map {|v|
    {id:v[:id],
     value:v[:text],
     tokens:v[:text].split(/\s+/)
    }
  }.to_json
end


get '/tags/refs/query_json/:query' do |query|
  halt_unless_auth('review_view')
  require 'json'
  content_type :json

  res=$db["SELECT id, text,COUNT(*) as n from tags t INNER JOIN tag_bw_cds tec ON t.id=tec.tag_id WHERE INSTR(text,?)>0 and decision='yes' GROUP BY t.text ORDER BY n DESC LIMIT 10", query]
  res.map {|v|
    {id:v[:id],
     value:v[:text],
     tokens:v[:text].split(/\s+/)
    }
  }.to_json
end



get '/tags/systematic_review/:rs_id/query_json/:query' do |rs_id,query|
  halt_unless_auth('review_view')
  require 'json'
  content_type :json
  
  res=$db["SELECT id, text,COUNT(*) as n from tags t INNER JOIN tag_in_cds tec ON t.id=tec.tag_id WHERE INSTR(text,?)>0 and decision='yes' and systematic_review_id=? GROUP BY t.text ORDER BY n DESC LIMIT 10", query, rs_id ]
  res.map {|v|
    {id:v[:id],
     value:v[:text],
     tokens:v[:text].split(/\s+/)
    }
  }.to_json
end

get '/tags/systematic_review/:rs_id/ref/query_json/:query' do |rs_id,query|
  halt_unless_auth('review_view')
  require 'json'
  content_type :json

  res=$db["SELECT id, text,COUNT(*) as n from tags t INNER JOIN tag_bw_cds tec ON t.id=tec.tag_id WHERE INSTR(text,?)>0 and decision='yes' and systematic_review_id=? GROUP BY t.text ORDER BY n DESC LIMIT 10", query, rs_id ]
  res.map {|v|
    {id:v[:id],
     value:v[:text],
     tokens:v[:text].split(/\s+/)
    }
  }.to_json
end



post '/tag/delete_rs' do
  halt_unless_auth('tag_edit')
  rs=SystematicReview[params['rs_id']]
  tag=Tag[params['tag_id']]
  return 404 if rs.nil? or tag.nil?
  $db.transaction(:rollback=>:reraise) {
    TagInCd.where(:tag_id=>tag.id, :systematic_review_id=>rs.id).delete
    if TagInCd.where(:tag_id=>tag.id).empty? and TagBwCd.where(:tag_id=>tag.id).empty?
      Tag[tag.id].delete
    end
  }
  return 200
end


# Not supported code
#
# get '/tag/:tag_id/review/:rs_id/assign_user/:user_id' do |tag_id,rs_id,user_id|
#   tag=Tag[tag_id]
#   revision=SystematicReview[rs_id]
#   usuario=User[user_id]
#   tec_cd_id=TagInCd.cds_rs_tag( revision,tag,true,revision.stage).select_map(:id)
#   a_cd=AllocationCd.where(:systematic_review_id=>rs_id,:user_id=>user_id, :canonical_document_id=>tec_cd_id).select_map(:canonical_document_id)
#   por_agregar=tec_cd_id-a_cd
#     if por_agregar.length>0
#       $db.transaction(:rollback=>:reraise) do
#         por_agregar.each do |cd_id|
#         AllocationCd.insert(:systematic_review_id=>rs_id,:user_id=>user_id, :canonical_document_id=>cd_id, :status=>'assigned')
#         end
#       end
#       agregar_mensaje("Agregados cd #{por_agregar.join(',')}  a usuario #{user_id} en revision sistematica #{revision.name}")
#     end
#
#   redirect back
# end