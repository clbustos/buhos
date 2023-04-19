# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2023, Claudio Bustos Navarrete
# All rights reserved.
# Licensed BSD 3-Clause License
# See LICENSE file for more information

# @!group Systematic reviews

# Get a list of systematic Reviews
get '/reviews' do
  halt_unless_auth('review_view')
  @user=User[session['user_id']]
  @show_inactives=params['show_inactives']
  @show_inactives||='only_actives'
  @show_only_user=params['show_only_user']
  @show_only_user||='yes'
  if @show_only_user=='yes'
    @reviewes=SystematicReview.get_reviews_by_user(@user.id)
  else
    @reviewes=SystematicReview
  end


  @reviewes=@reviewes.where(:active => 1) if @show_inactives=='only_actives'


  haml :reviews, escape_html: false
end

# Form to create a new systematic review
get '/review/new' do
  halt_unless_auth('review_edit')

  require 'date'
  title(t(:Systematic_review_new))
  first_group=User[session['user_id']].groups.first
  if first_group.nil?
    add_message(I18n::t(:user_should_be_included_in_one_group_at_least), :error)
    redirect back
  end
  @current_year=DateTime.now.year
  administrator=first_group[:group_administrator]
  @review=SystematicReview.new(      active:            true,
                                     stage:             "search",
                                     group:             first_group,
                                     sr_administrator:  administrator,
                                     date_creation:     Date.today,
                                     year_start:        @current_year,
                                     year_end:        @current_year
                                     )
  @taxonomy_categories_id=[]

  haml "systematic_reviews/edit".to_sym, escape_html: false
end

# View a specific review
get "/review/:id" do |id|
  halt_unless_auth('review_view')

  @review=SystematicReview[id]
  ##$log.info(@names_trs)
  raise Buhos::NoReviewIdError, id if !@review
#  return 404 if !@review

  @taxonomy_categories  = @review.taxonomy_categories_hash
  @criteria             = @review.criteria_hash

  haml "systematic_reviews/view", escape_html: false
end

get '/review/:id/dashboard' do |id|
  halt_unless_auth('review_edit')
  @review=SystematicReview[id]
  raise Buhos::NoReviewIdError, id if !@review
  @user=User[session['user_id']]


  haml "systematic_reviews/dashboard".to_sym, escape_html: false

end

# Form to edit a specific review
get "/review/:id/edit" do |id|
  halt_unless_auth('review_edit')

  @review=SystematicReview[id]
  raise Buhos::NoReviewIdError, id if !@review
  @taxonomy_categories_id=@review.taxonomy_categories_id
  title(t(:Systematic_review_edit, sr_name:@review.name))
  haml "systematic_reviews/edit".to_sym, escape_html: false
end


# Create (id=0) or edit(id>0)a Systematic review
# @see /review/:id/edit
# @see /review/new
post '/review/update' do
  halt_unless_auth('review_edit')

  id=params['review_id']
  otros_params=params
  otros_params.delete("review_id")
  otros_params.delete("captures")
  strc=params.delete("srtc")
  criteria=params.delete("criteria")
  criteria||={'inclusion'=>[], 'exclusion'=>[]}
  otros_params=otros_params.inject({}) {|ac,v|
    ac[v[0].to_sym]=v[1];ac
  }


  #  aa=SystematicReview.new
  #$log.info(otros_params)

  $db.transaction(:rollback=>:reraise) do
    if(id=="")
      id=SystematicReview.insert(otros_params)
    else
      revision=SystematicReview[id]
      revision.update(otros_params)
    end

    # Process criteria
    criteria_processor=Buhos::CriteriaProcessor.new(SystematicReview[id])
    criteria_processor.update_criteria(criteria['inclusion'], criteria['exclusion'])

    # Process the srtc

    Systematic_Review_SRTC.where(:sr_id=>id).delete
    if !strc.nil? and !strc.keys.nil?
      strc.keys.each {|key|
        Systematic_Review_SRTC.insert(:sr_id=>id, :srtc_id=>key.to_i)
      }
    end



  end

  redirect url("/review/#{id}/dashboard")
end













# List of review files
get '/review/:id/files' do |id|
  halt_unless_auth('review_view', 'file_view')
  @review=SystematicReview[id]
  raise Buhos::NoReviewIdError, id if !@review
  @file_rs=IFile.join(:file_srs, :file_id => :id).left_join(:file_cds, :file_id => :file_id).where(:systematic_review_id => id).order_by(:filename)
  @modal_files=get_modal_files
  @canonical_documents_h=@review.canonical_documents.order(:title).as_hash
  @cd_validos_id=@review.cd_id_by_stage(@review.stage)
  @cd_validos=@canonical_documents_h.find_all {|v| @cd_validos_id.include? v[0]}.map{|v| v[1]}
  @usuario=User[session['user_id']]
  haml "systematic_reviews/files".to_sym, escape_html: false
end


# Add one or more files to a review
post '/review/files/add' do
  halt_unless_auth('review_edit', 'file_admin')

  #$log.info(params)
  @review=SystematicReview[params['systematic_review_id']]
  raise Buhos::NoReviewIdError, id if !@review
  files=params['files']
  cd=nil
  cd_id=params['canonical_document_id']
  if cd_id
    cd=CanonicalDocument[cd_id]
    raise Buhos::NoCdIdError, cd_id if cd.nil?
  end

  if files
    results=Result.new
    files.each do |file|

      file_proc=FileProcessor.new(file, dir_files)
      file_proc.add_to_sr(@review)
      file_proc.add_to_cd(cd) if cd
      results.success(I18n::t("search.successful_upload", filename:File.basename(file_proc.filepath), sr_name:@review.name))
    end
    add_result results
  else
    add_message(I18n::t(:Files_not_uploaded), :error)
  end
  redirect back
end

# Go to next stage, if complete
get '/review/:id/advance_stage' do |id|
  halt_unless_auth('review_admin')

  @review=SystematicReview[id]
  raise Buhos::NoReviewIdError, id if !@review

  @ars=AnalysisSystematicReview.new(@review)
  if (@ars.stage_complete?(@review.stage))
    stage_i=get_stages_ids.index(@review[:stage].to_sym)
    #$log.info(stage_i)
    return 405 if stage_i.nil?
    @review.update(:stage=>get_stages_ids[stage_i+1])
    add_message(I18n::t(:stage_complete))
    redirect("/review/#{@review[:id]}/administration/#{@review[:stage]}")
  else
    add_message(I18n::t(:stage_not_yet_complete), :error)
    redirect back
  end
end

get '/review/:rev_id/reference/:ref_id/assign_canonical_document' do |rev_id, r_id|
  halt_unless_auth('reference_edit')
  @reference=Reference[r_id]
  raise Buhos::NoReferenceIdError, r_id if @reference.nil?
  @review=SystematicReview[rev_id]
  raise Buhos::NoReviewIdError, rev_id if @review.nil?
  @cds=nil
  @query=params['query']
  if @query
    @cds=@review.canonical_documents
    @cds=@cds.where(Sequel.like(:author, "%#{@query['author'].chomp}%")) if @query['author'].to_s!=""
    @cds=@cds.where(:year=>@query['year']) if @query['year'].to_s!=""
    @cds=@cds.where(Sequel.like(:title, "%#{@query['title'].chomp}%")) if @query['title'].to_s!=""
    @cds=@cds.order(:author).limit(20)
  else
    @query={}
  end

  haml "systematic_reviews/reference_assign_canonical_document".to_sym, escape_html: false
end




get '/review/:id/delete' do |id|
  halt_unless_auth('review_admin')

  @review=SystematicReview[id]
  raise Buhos::NoReviewIdError, id if !@review

  haml "systematic_reviews/delete_warning".to_sym, escape_html: false
end


post '/review/:id/delete2' do |id|
  id2=params['sr_id']
  @review=SystematicReview[id]
  raise Buhos::NoReviewIdError, id if !@review
  raise "#{id} and #{id2} should coincide" if id.to_s!=id2.to_s

  if @review.delete
    add_message(t("systematic_review.delete_successful"))
  else
    add_message(t("systematic_review.delete_unsuccessful"))
  end
  redirect url('/reviews')
end




# @!endgroup
