# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2025, Claudio Bustos Navarrete
# All rights reserved.
# Licensed BSD 3-Clause License
# See LICENSE file for more information

# @!group Systematic reviews

helpers do
  def review_groups_for(user_id, can_manage_groups)
    return Group.dataset if can_manage_groups

    Group.where(id: GroupsUser.where(user_id: user_id).select(:group_id))
  end

  def review_transfer_groups(groups, review)
    required_users=review.users_required_for_group_transfer
    return groups if required_users.empty?

    matching_groups=GroupsUser.where(user_id: required_users).
      group(:group_id).having { count(:user_id) =~ required_users.size }.select(:group_id)
    groups.where(Sequel.|({id: review.group_id}, {id: matching_groups}))
  end

  def prepare_review_group_options
    @can_manage_groups=auth_to('group_admin')
    groups=review_groups_for(session['user_id'], @can_manage_groups)
    unless @review.new?
      halt 403 unless groups.where(id: @review.group_id).first
      groups=review_transfer_groups(groups, @review)
    end
    @can_create_review_group=@review.new? ||
      (independent_researcher? && (@review.users_required_for_group_transfer - [session['user_id']]).empty?)
    @review_groups=groups.order(:name, :id).all
    @review_group_members={}
    if @can_manage_groups
      @review_groups.each do |group|
        @review_group_members[group.id]=group.users_dataset.order(:name, Sequel[:users][:id]).all
      end
    end
  end
end

# Get a list of systematic Reviews
get '/reviews' do
  halt_unless_auth('review_view')
  @user=User[session['user_id']]
  @show_inactives=params['show_inactives']
  @show_inactives||='only_actives'
  @show_only_user=params['show_only_user']
  @show_only_user||='yes'
  if @show_only_user=='yes' || scoped_researcher?
    @reviewes=SystematicReview.get_reviews_by_user(@user.id)
  else
    @reviewes=SystematicReview
  end


  @reviewes=@reviewes.where(:active => 1) if @show_inactives=='only_actives'


  haml :reviews, escape_html: false
end

# Form to create a new systematic review
get '/review/new' do
  halt 403 unless can_create_review?

  require 'date'
  title(t(:Systematic_review_new))
  @current_year=DateTime.now.year
  @review=SystematicReview.new(      active:            true,
                                     stage:             "search",
                                     date_creation:     Date.today,
                                     year_start:        @current_year,
                                     year_end:          @current_year,
                                     show_other_users_tags: true,
                                     blind_reference_screening: false
                                     )
  @taxonomy_categories_id=[]
  prepare_review_group_options

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

  haml "systematic_reviews/view".to_sym, escape_html: false
end

get '/review/:id/dashboard' do |id|
  halt_unless_auth(scoped_researcher? ? 'review_view' : 'review_edit')
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
  prepare_review_group_options
  @taxonomy_categories_id=@review.taxonomy_categories_id
  title(t(:Systematic_review_edit, sr_name:@review.name))
  haml "systematic_reviews/edit".to_sym, escape_html: false
end


# Create (id=0) or edit(id>0)a Systematic review
# @see /review/:id/edit
# @see /review/new
post '/review/update' do
  id=params['review_id']
  creating=id == ''
  halt 403 unless creating ? can_create_review? : auth_to('review_edit')
  halt 400 unless creating || id.to_s.match?(/\A[1-9][0-9]*\z/)
  strc=params['srtc']
  criteria=params['criteria']
  criteria||={'inclusion'=>[], 'exclusion'=>[]}
  fields=%i[name description date_creation research_questions objectives year_start year_end keywords
            n_min_rr_rtr active show_other_users_tags blind_reference_screening stage conflict_of_interest]
  otros_params=(fields + SystematicReview::EXPECTED_REVIEWER_FIELDS).each_with_object({}) do |field, values|
    values[field]=params[field.to_s] if params.key?(field.to_s)
  end

  SystematicReview::EXPECTED_REVIEWER_FIELDS.each do |field|
    next unless otros_params.key?(field)
    value=otros_params[field].to_s
    halt 400, t(:Expected_reviewers_invalid) unless value.match?(/\A[0-9]+\z/) && value.to_i > 0
    otros_params[field]=value.to_i
  end

  transaction_options={rollback: :reraise}
  transaction_options[:mode]=:immediate if $db.database_type == :sqlite
  $db.transaction(transaction_options) do
    user_id=session['user_id']
    can_manage_groups=auth_to('group_admin')
    groups=review_groups_for(user_id, can_manage_groups)
    unless creating
      revision=SystematicReview.where(id: id).for_update.first
      raise Buhos::NoReviewIdError, id unless revision
      halt 403 unless groups.where(id: revision.group_id).first
    end

    group_mode=params['group_mode']
    group_mode ||= (creating && params['group_id'].to_s.empty? ? 'new' : 'existing')
    if group_mode == 'new' && (creating || independent_researcher?)
      if revision && !(revision.users_required_for_group_transfer - [user_id]).empty?
        halt 422, t('systematic_review.group_missing_participants')
      end
      name=otros_params[:name] || revision&.name
      halt 400 if name.to_s.strip.empty?
      group=Group.create(name: name, description: otros_params.fetch(:description, revision&.description),
                         group_administrator: user_id)
      GroupsUser.insert(group_id: group.id, user_id: user_id)
      otros_params.merge!(group_id: group.id, sr_administrator: user_id)
    elsif group_mode == 'existing'
      group_id=params['group_id'] || revision&.group_id
      halt 400 unless group_id.to_s.match?(/\A[1-9][0-9]*\z/)
      group=groups.where(id: group_id).first
      halt 403, t('systematic_review.group_unavailable') unless group
      moving=revision && revision.group_id != group.id
      if moving && !review_transfer_groups(groups, revision).where(id: group.id).first
        halt 422, t('systematic_review.group_missing_participants')
      end

      default_administrator=if independent_researcher? && (creating || moving)
        user_id
      elsif creating || moving
        group.group_administrator
      else
        revision.sr_administrator
      end
      administrator=params['sr_administrator'] || default_administrator
      if administrator
        halt 400 unless administrator.to_s.match?(/\A[1-9][0-9]*\z/)
        administrator=administrator.to_i
        halt 403 unless can_manage_groups || administrator == default_administrator
      end
      if (creating || moving || administrator != revision.sr_administrator) &&
         !GroupsUser.where(group_id: group.id, user_id: administrator).first
        halt 422, t('systematic_review.group_administrator_not_member')
      end
      otros_params[:group_id]=group.id
      otros_params[:sr_administrator]=administrator if administrator
    else
      halt 400
    end

    if creating
      id=SystematicReview.insert(otros_params)
    else
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
  @file_extraction_information_by_file=FileExtractionInformation.
    where(:systematic_review_id=>id).
    all.
    group_by {|file_extraction_information| file_extraction_information[:file_id]}
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
  halt_unless_auth('review_admin')
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
