# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2025, Claudio Bustos Navarrete
# All rights reserved.
# Licensed BSD 3-Clause License
# See LICENSE file for more information



# @!group stages administration
# List of administration interfaces by stage


require 'serrano'
get '/review/:id/administration_stages' do |id|
  halt_unless_auth_any('review_admin', 'review_admin_view')
  @review=SystematicReview[id]
  raise Buhos::NoReviewIdError, id if !@review
  @ars=AnalysisSystematicReview.new(@review)
  haml "systematic_reviews/administration_stages".to_sym, escape_html: false

end

# Interface to administrate a stage
get '/review/:id/administration/:stage' do |id,stage|
  halt_unless_auth_any('review_admin', 'review_admin_view')
  @review=SystematicReview[id]

  raise Buhos::NoReviewIdError, id if !@review


  @stage=stage
  @ars=AnalysisSystematicReview.new(@review)
  @cd_without_allocation=@ars.cd_without_allocations(stage)
  @text_decision_cd= Buhos::AnalysisCdDecisions.new(@review, stage)

  @cds_id=@review.cd_id_by_stage(stage)
  @cds=CanonicalDocument.where(:id=>@cds_id)
  @cds_hash=@cds.as_hash
  @files_by_cd=@ars.files_by_cd
  ## Aquí calcularé cuantos si y no hay por categoría
  res_stage=@ars.resolution_by_cd(stage)
  begin
    @categorizador=CategorizerSr.new(@review) unless stage==:search
    @aprobacion_categorias=@categorizador.categorias_cd_id.inject({}) {|ac,v|
      cd_validos=res_stage.keys & (v[1])
      n=cd_validos.length
      if n==0
        ac[v[0]] = {n:0, p:nil}
      else
        ac[v[0]] = {n:n, p: cd_validos.find_all {|vv|  res_stage[vv]=='yes' }.length /   n.to_f}
      end
      ac
    }
  rescue LoadError
    @categorizador=nil
  end
  #  $log.info(p_aprobaciones_categoria)
  @name_stage=get_stage_name(@stage)

  @user_id=session['user_id']
  @modal_files=get_modal_files

  if %w{screening_title_abstract screening_references review_full_text}.include? stage
    haml "systematic_reviews/administration_reviews".to_sym, escape_html: false
  elsif stage==Buhos::Stages::STAGE_REVIEW_EXTRACT_INFORMATION.to_s
    @extract_information_stats=extract_information_administration_stats(@review, @cds_id, @cd_without_allocation)
    haml "systematic_reviews/administration_extract_information".to_sym, escape_html: false
  else
    haml "systematic_reviews/administration_#{stage}".to_sym, escape_html: false
  end
end

def extract_information_administration_stats(review, cds_id, cd_without_allocation)
  stage=Buhos::Stages::STAGE_REVIEW_EXTRACT_INFORMATION.to_s
  cds_id=cds_id.map(&:to_i)
  fields=review.fields.map {|field| field[:name].to_sym}
  quality_criteria_ids=SrQualityCriterion.where(:systematic_review_id=>review[:id]).map(:quality_criterion_id)
  quality_active=quality_criteria_ids.any?

  form_information_by_pair={}
  if $db.table_exists?(review.analysis_cd_tn.to_sym)
    review.analysis_cd.where(:canonical_document_id=>cds_id).each do |row|
      has_form_information=fields.any? do |field|
        value=row[field]
        !value.nil? && value.to_s.strip!=''
      end
      form_information_by_pair[[row[:canonical_document_id].to_i, row[:user_id].to_i]]=true if has_form_information
    end
  end

  file_information_by_pair={}
  if defined?(FileExtractionInformation)
    FileExtractionInformation.where(:systematic_review_id=>review[:id], :canonical_document_id=>cds_id).each do |file_information|
      file_information_by_pair[[file_information[:canonical_document_id].to_i, file_information[:user_id].to_i]]=true
    end
  end

  quality_by_pair={}
  if quality_active
    CdQualityCriterion.
      where(:systematic_review_id=>review[:id], :canonical_document_id=>cds_id, :quality_criterion_id=>quality_criteria_ids).
      group_and_count(:canonical_document_id, :user_id).
      each do |row|
        quality_by_pair[[row[:canonical_document_id].to_i, row[:user_id].to_i]]=row[:count].to_i
      end
  end

  users=Array(review.group_users)
  users_by_id=users.each_with_object({}) {|user, memo| memo[user[:id].to_i]=user}
  assigned_pairs=AllocationCd.where(:systematic_review_id=>review[:id], :stage=>stage, :canonical_document_id=>cds_id).all

  user_statuses=users.each_with_object({}) do |user, memo|
    memo[user[:id].to_i]={user_id:user[:id].to_i, user:user, assigned_count:0, information_count:0, quality_count:0, complete_count:0}
  end

  assigned_statuses=assigned_pairs.map do |allocation|
    cd_id=allocation[:canonical_document_id].to_i
    user_id=allocation[:user_id].to_i
    pair=[cd_id, user_id]
    has_information=form_information_by_pair[pair] || file_information_by_pair[pair]
    quality_count=quality_by_pair[pair].to_i
    has_quality=!quality_active || quality_count>=quality_criteria_ids.length
    complete=has_information && has_quality

    user_statuses[user_id]||={user_id:user_id, user:users_by_id[user_id] || User[user_id], assigned_count:0, information_count:0, quality_count:0, complete_count:0}
    user_statuses[user_id][:assigned_count]+=1
    user_statuses[user_id][:information_count]+=1 if has_information
    user_statuses[user_id][:quality_count]+=1 if quality_active && has_quality
    user_statuses[user_id][:complete_count]+=1 if complete

    {
      canonical_document_id:cd_id,
      user_id:user_id,
      has_information:has_information,
      has_quality:has_quality,
      complete:complete
    }
  end

  document_statuses=cds_id.map do |cd_id|
    form_users=form_information_by_pair.keys.find_all {|pair| pair[0]==cd_id}.map {|pair| pair[1]}
    file_users=file_information_by_pair.keys.find_all {|pair| pair[0]==cd_id}.map {|pair| pair[1]}
    quality_users=quality_by_pair.find_all {|pair, count| pair[0]==cd_id && count.to_i>=quality_criteria_ids.length}.map {|pair, _count| pair[1]}
    has_information=(form_users | file_users).any?
    has_quality=!quality_active || quality_users.any?
    {
      canonical_document_id:cd_id,
      has_form_information:form_users.any?,
      has_file_information:file_users.any?,
      has_information:has_information,
      has_quality:has_quality,
      complete:has_information && has_quality,
      assigned_count:assigned_pairs.count {|allocation| allocation[:canonical_document_id].to_i==cd_id}
    }
  end

  documents_complete=document_statuses.all? {|status| status[:complete]}
  assigned_complete=assigned_statuses.all? {|status| status[:complete]}
  stage_complete=cds_id.any? && cd_without_allocation.empty? && documents_complete && assigned_complete

  {
    quality_active:quality_active,
    quality_criteria_count:quality_criteria_ids.length,
    total_documents:cds_id.length,
    documents_with_information:document_statuses.count {|status| status[:has_information]},
    documents_with_quality:document_statuses.count {|status| status[:has_quality]},
    complete_documents:document_statuses.count {|status| status[:complete]},
    assigned_total:assigned_statuses.length,
    assigned_complete:assigned_statuses.count {|status| status[:complete]},
    stage_complete:stage_complete,
    user_statuses:user_statuses.values,
    document_statuses:document_statuses
  }
end


get '/review/:id/stage/:stage/pattern/:patron/view' do |id,stage,patron_s|
  halt_unless_auth_any('review_admin', 'review_admin_view')
  @review=SystematicReview[id]
  @stage=stage
  raise Buhos::NoReviewIdError, id if !@review
  @ars=AnalysisSystematicReview.new(@review)
  @pattern=@ars.pattern_from_s(patron_s)
  @pattern_name=@ars.pattern_name(@pattern)
  @text_decision_cd= Buhos::AnalysisCdDecisions.new(@review, stage)
  @cds=@ars.cd_from_pattern(stage, @pattern)
  @user_id=session['user_id']
  haml "systematic_reviews/administration_reviews_documents_by_decision".to_sym, escape_html: false
end

# Set a resolution for a given pattern

get '/review/:id/stage/:stage/pattern/:patron/resolution/:resolution' do |id,stage,patron_s,resolution|
  halt_unless_auth_any('review_admin', 'review_admin_view')
  @review=SystematicReview[id]
  raise Buhos::NoReviewIdError, id if !@review

  @ars=AnalysisSystematicReview.new(@review)
  patron=@ars.pattern_from_s(patron_s)
  cds=@ars.cd_from_pattern(stage, patron)
  resolved_cds=Resolution.where(:systematic_review_id=>id,
                                :canonical_document_id=>cds,
                                :stage=>stage,
                                :resolution=>[Resolution::RESOLUTION_ACCEPT, Resolution::RESOLUTION_REJECT]).
      map(:canonical_document_id)
  cds_to_resolve=cds-resolved_cds

  $db.transaction(:rollback=>:reraise) do
    cds_to_resolve.each do |cd_id|
      Resolution.set_for_document(
        systematic_review_id:id,
        canonical_document_id:cd_id,
        stage:stage,
        resolution:resolution,
        user_id:session['user_id'],
        commentary:"Resuelto en forma masiva en #{DateTime.now.to_s}"
      )
    end
  end
  add_message(I18n::t("resolution_for_n_documents", resolution:resolution, n:cds_to_resolve.length))
  redirect back
end


# Retrieve information from Crossref for all canonical documents
# approved for a given stage
# TODO: Move this to independent class

get '/review/:rev_id/stage/:stage/generate_crossref_references' do |rev_id,stage|
  halt_unless_auth_any('review_admin')
  @review=SystematicReview[rev_id]
  @stage=stage
  raise Buhos::NoReviewIdError, id if !@review
  haml "/systematic_reviews/generate_crossref_references".to_sym, escape_html: false
end

get '/review/:rev_id/stage/:stage/generate_crossref_references_stream' do |rev_id,stage|
  halt_unless_auth_any('review_admin')
  @review=SystematicReview[rev_id]
  raise Buhos::NoReviewIdError, id if !@review
  result=Result.new

  start = request.env['HTTP_LAST_EVENT_ID'] ? request.env['HTTP_LAST_EVENT_ID'].to_i+1 : 0

  content_type "text/event-stream"
  #$log.info("Start:#{start}")
  stream do |out|
    begin
      dois_agregados=0
      cd_i=Resolution.where(:systematic_review_id=>rev_id, :resolution=>"yes", :stage=>stage.to_s).map {|v|v [:canonical_document_id]}.uniq
      if start>=cd_i.length
        out << "data:CLOSE\n\n"
        return 200
      end
      start.upto(cd_i.length-1).each do |i|
        $log.info(i)
        cd_id=cd_i[i]
        out << "id: #{i}\n"

        @cd=CanonicalDocument[cd_id]
        out << "data: Processing '#{t(:Canonical_document)}:#{@cd[:title]}'\n\n"
        # first, we process all records pertinent with this canonical document.
        records=Record.where(:canonical_document_id=>cd_id)
        out << "data: #{I18n::t(:No_records_search)}\n\n" if records.empty?
        rcp=RecordCrossrefProcessor.new(records,$db)
        out << "data: #{rcp.result.message}\n\n"
        result.add_result(rcp.result)
        if @cd.crossref_integrator
          begin
            # Agregar dois a references
            @cd.references_performed.where(:canonical_document_id=>nil).each do |ref|
              # primero agregamos doi si podemos
              # Si tiene doi, tratamos de
              rp=ReferenceProcessor.new(ref)
              if ref.doi.nil?
                dois_agregados+=1 if rp.process_doi
              end

              if !ref.doi.nil?
                res_doi=ref.add_doi(ref[:doi])
                out << "data: #{res_doi.message}\n\n"
                result.add_result(res_doi)
              end
            end
          rescue StandardError=>e
            out << "data: #{e.message}\n\n"
            result.error(e.message)
          end
        else
          result.error(I18n::t("error.error_on_add_crossref_for_cd", cd_title:@cd[:title]))
        end
      end
      mes_dois_added=I18n::t(:Search_add_doi_references, :count=>dois_agregados)
      result.info(mes_dois_added)
      out << "data: #{mes_dois_added}\n\n"
    rescue Faraday::ConnectionFailed=>e
      result.error("#{t(:No_connection_to_crossref)}:#{e.message}")
    end
    add_result(result)
    out << "data:CLOSE\n\n"
  end
  #redirect back
end

# @!endgroup

# @!group Allocation of canonical documents to users






post '/review/:rev_id/administration/:stage/cd_assignations_excel/:mode' do |rev_id, stage, mode|
  halt_unless_auth('review_admin')
  review=SystematicReview[rev_id]
  raise Buhos::NoReviewIdError, rev_id if !review

  cds_id=review.cd_id_by_stage(stage)
  stage=stage
  cds=CanonicalDocument.where(:id=>cds_id).order(:author)
  users_grupos=review.group_users
  archivo=params.delete("file")

  if mode=="load"
    require 'simple_xlsx_reader'
    SimpleXlsxReader.configuration.auto_slurp = true
    doc = SimpleXlsxReader.open(archivo["tempfile"])
    sheet=doc.sheets.first
    header=sheet.headers
    id_index=header.find_index("id")
    users_assignation={}
    header.each_index { |i|
      if header[i]=~/\[(\d+)\].+/
        users_assignation[i]=$1
      end
    }
    number_of_actions=0
    $db.transaction(:rollback => :reraise) do
      sheet.data.each do |row|
        cd_id=row[id_index]
        if cd_id.nil?
          add_message("Row without information", :error)
        else
          user_allocations=AllocationCd.where(:systematic_review_id=>review[:id], :canonical_document_id=>cd_id, :stage=>stage ).to_hash(:user_id)
          #$log.debug(user_allocations)
          users_assignation.each do |i,user_id|
            if !row[i].nil?
              #$log.debug("#{row[i]}: #{user_id}")
              if row[i].to_i==0 and user_allocations[user_id.to_i]
                number_of_actions+=1
               # $log.debug("Deleting")
                  AllocationCd.where(:systematic_review_id=>review[:id], :canonical_document_id=>cd_id, :stage=>stage, :user_id=>user_id).delete
              elsif row[i].to_i==1 and !user_allocations[user_id.to_i]
              #$log.debug("assing")
                number_of_actions+=1
                AllocationCd.insert(:systematic_review_id=>review[:id], :canonical_document_id=>cd_id, :stage=>stage, :user_id=>user_id, :status=>"Massive assign")
              end
            end
          end
        end
      end
    end


    add_message(t("systematic_review_page.cd_assignations_number", n:number_of_actions))
    redirect back
    # Aquí es-> fp.read
  else
    raise "Not implemented"
  end

end



get '/review/:sr_id/stage/:stage/import_export_decisions' do |sr_id, stage|
  halt_unless_auth_any('review_admin', 'review_admin_view')
  @review=SystematicReview[sr_id]
  raise Buhos::NoReviewIdError, sr_id if !@review
  @stage=stage.to_sym
  @name_stage=get_stage_name(@stage)

  haml "systematic_reviews/administration_import_export_decisions".to_sym, escape_html: false
end

get '/review/:rev_id/administration/:stage/cd_assignations_excel/:mode' do |rev_id, stage, mode|
  halt_unless_auth_any('review_admin', 'review_admin_view')
  review=SystematicReview[rev_id]
  raise Buhos::NoReviewIdError, rev_id if !review

  cds_id=review.cd_id_by_stage(stage)
  stage=stage
  cds=CanonicalDocument.where(:id=>cds_id).order(:author)
  users_grupos=review.group_users
  if mode=="save" or mode=="save_only_not_allocated" or mode=="save_only_not_resolved"
    require 'caxlsx'
    package = Axlsx::Package.new
    wb = package.workbook
    blue_cell = wb.styles.add_style  :fg_color => "0000FF", :sz => 14, :alignment => { :horizontal=> :center }
    wrap_text = wb.styles.add_style alignment: { wrap_text: true }
    little_text = wb.styles.add_style
    wb.add_worksheet(:name => t(:Assign)) do |sheet|
      header=["id","reference"]+users_grupos.map {|v| "[#{v[:id]}] #{v[:name]}"}
      sheet.add_row header, :style=> [blue_cell]*(2+users_grupos.count)
      cds.each do |cd|
        row=[cd[:id], cd.ref_apa_6]
        user_allocations=AllocationCd.where(:systematic_review_id=>review[:id], :canonical_document_id=>cd[:id], :stage=>stage ).to_hash(:user_id)
        resolution=Resolution[:systematic_review_id=>review[:id], :canonical_document_id=>cd[:id], :stage=>stage]
        $log.info(resolution)
        asignaciones= users_grupos.map {|user|  user_allocations[user[:id]].nil?  ? 0 : 1  }
        total=asignaciones.inject(0) {|sum,v|sum+v}
        if mode=="save" or (mode=="save_only_not_allocated" and total==0) or (mode=="save_only_not_resolved" and not resolution)
          sheet.add_row row+asignaciones, style: ([wrap_text]*2)+[nil]*users_grupos.count
        end
      end
      sheet.column_widths *([nil, 30]+ [5]*users_grupos.count)
      sheet.column_widths *([nil, 30]+ [5]*users_grupos.count)
    end

    headers 'Content-Type' => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    headers 'Content-Disposition' => "attachment; filename=cd_assignation_#{rev_id}_#{stage}.xlsx"
    package.to_stream
  else

    raise "Not implemented"
  end

end

# List of all canonical documents without allocation
# to users

# List of allocations of canonical documents to users
get '/review/:rev_id/administration/:stage/cd_assignations' do |rev_id, stage|
  halt_unless_auth_any('review_admin', 'review_admin_view')
  @review=SystematicReview[rev_id]
  raise Buhos::NoReviewIdError, rev_id if !@review

  @cds_id=@review.cd_id_by_stage(stage)
  @ars=AnalysisSystematicReview.new(@review)
  @stage=stage

  @url="/review/#{rev_id}/administration/#{stage}/cd_assignations"



  @cds_pre=CanonicalDocument.where(:id=>@cds_id) #.order(:author)

  @pager=get_pager
  @pager.order||="title__asc"
  @order_criteria={:title=>I18n.t(:Title), :year=> I18n.t(:Year), :author=>I18n.t(:Author)}
  @cds=@pager.adapt_cds(@cds_pre)

  @type="all"
  haml "systematic_reviews/cd_assignations_to_user".to_sym, escape_html: false
end

get '/review/:rev_id/administration/:stage/canonical_document_status' do |rev_id, stage|
  halt_unless_auth_any('review_admin', 'review_admin_view')
  @review=SystematicReview[rev_id]
  raise Buhos::NoReviewIdError, rev_id if !@review

  @stage=stage
  @ars=AnalysisSystematicReview.new(@review)
  @cds_id=@review.cd_id_by_stage(stage)
  @cds=CanonicalDocument.where(:id=>@cds_id)
  @files_by_cd=@ars.files_by_cd
  @name_stage=get_stage_name(@stage)
  @modal_files=get_modal_files
  @missing_file_reports_by_cd=DocumentReport.
    where(
      systematic_review_id:rev_id,
      canonical_document_id:@cds_id,
      report_type:DocumentReport::MISSING_FILE
    ).
    exclude(status:'ignored').
    select_group(:canonical_document_id).
    select_append { count(:user_id).as(:users_count) }.
    to_hash(:canonical_document_id, :users_count)

  haml "systematic_reviews/administration_canonical_document_status".to_sym, escape_html: false
end


get '/review/:rev_id/administration/:stage/cd_without_allocations' do |rev_id, stage|
  halt_unless_auth_any('review_admin', 'review_admin_view')
  @review=SystematicReview[rev_id]
  raise Buhos::NoReviewIdError, rev_id if !@review

  @ars=AnalysisSystematicReview.new(@review)
  @cds_id=@ars.cd_without_allocations(stage).map {|cd|cd[:id]}

  @stage=stage

  @cds_pre=CanonicalDocument.where(:id=>@cds_id) #.order(:author)

  @pager=get_pager
  @pager.order||="title__asc"
  @order_criteria={:title=>I18n.t(:Title), :year=> I18n.t(:Year), :author=>I18n.t(:Author)}

  @cds=@pager.adapt_cds(@cds_pre)
  @type="without_allocation"


  haml "systematic_reviews/cd_assignations_to_user".to_sym , escape_html: false
end


# Allocate canonical documents to a user
# if type='all', all documents are allocated
# if type='without_allocation', only documents without allocation are allocated

get '/review/:rev_id/stage/:stage/add_assign_user/:user_id/:type' do |rev_id, stage, user_id,type|
  halt_unless_auth('review_admin')
  @review=SystematicReview[rev_id]
  raise Buhos::NoReviewIdError, rev_id if !@review
  if type=='all'
    @cds_id=@review.cd_id_by_stage(stage)
  elsif type=='without_allocation'
    ars=AnalysisSystematicReview.new(@review)
    @cds_id_previous=ars.cd_id_assigned_by_user(stage,user_id)
    @cds_id_add=ars.cd_without_allocations(stage).map(:id)
    @cds_id=(@cds_id_previous+@cds_id_add).uniq
  end
  add_result(AllocationCd.update_assignation(rev_id, @cds_id, user_id,stage, 'massive_assigment'))
  redirect back
end

# Remove all documents allocations from a user

get '/review/:rev_id/stage/:stage/rem_assign_user/:user_id/:type' do |rev_id, stage, user_id, type|
  halt_unless_auth('review_admin')
  # Type doesn't have meaning here
  @review=SystematicReview[rev_id]
  raise Buhos::NoReviewIdError, rev_id if !@review
  add_result(AllocationCd.update_assignation(rev_id, [], user_id,stage))
  redirect back
end

get '/review/:rev_id/stage/:stage/reassign_user/:user_id' do |rev_id, stage, user_id|
  halt_unless_auth('review_admin')
  # Type doesn't have meaning here
  @review=SystematicReview[rev_id]
  raise Buhos::NoReviewIdError, rev_id if !@review
  @user=User[user_id]
  raise Buhos::NoUserIdError, user_id if !@user
  @asr=::Analysis_SR_Stage.new(@review, stage)
  @stage=stage

  @cdid_abu=@asr.cd_id_assigned_by_user(user_id)

  @resolved=@asr.cd_resolved_id

  @assigned_not_resolved_id=@cdid_abu-@resolved
  @cd_assigned_not_resolved=CanonicalDocument.where(id:@assigned_not_resolved_id).order_by(:year)


  haml "systematic_reviews/cd_reassignations".to_sym , escape_html: false

end

post '/review/reassign_cd_to_user' do
  rev_id=params['review_id']
  @review=SystematicReview[rev_id]
  raise Buhos::NoReviewIdError, rev_id if !@review
  user_id_from=params['user_id_from']
  @user_from=User[user_id_from]
  raise Buhos::NoUserIdError, user_id_from if !@user_from

  user_id_to=params['user_id_to']
  @user_to=User[user_id_to]
  raise Buhos::NoUserIdError, user_id_to if !@user_to

  @stage=params['stage']
  @asr=::Analysis_SR_Stage.new(@review, @stage)
  @cdid_abu=@asr.cd_id_assigned_by_user(user_id_from)

  @resolved=@asr.cd_resolved_id

  @assigned_not_resolved_id=@cdid_abu-@resolved

  if params['canonical_documents']
    canonical_documents=params['canonical_documents'].keys.map {|v| v.to_i}
    #$log.info(@assigned_not_resolved_id)
    #$log.info(canonical_documents)
    cds_id=@assigned_not_resolved_id & canonical_documents
    result=AllocationCd.reassign_assignations(rev_id, @stage, user_id_from, user_id_to, cds_id,
                                       ::I18n::t("systematic_review_page.massive_reassignation_from_to",
                                                 from:user_id_from,
                                                 to:user_id_to))
    add_result(result)
    redirect back

  else
    add_message(::I18n::t("systematic_review_page.should_assign_at_least_one_canonical_document"), :error)
    redirect url("/review/#{rev_id}/stage/#{@stage}/reassign_user/#{user_id_from}")
  end




end


# @!endgroup

# @!group Administration of documents without abstract

# List of documents without abstract

get '/review/:rev_id/stage/:stage/complete_empty_abstract_manual' do |rev_id, stage|
  halt_unless_auth_any('review_admin', 'review_admin_view')
  @review=SystematicReview[rev_id]
  raise Buhos::NoReviewIdError, rev_id if !@review
  @ars=AnalysisSystematicReview.new(@review)
  @stage=stage
  @cd_wo_abstract=@ars.cd_without_abstract(stage)
  haml "systematic_reviews/complete_abstract_manual".to_sym, escape_html: false
end

# Automatic retrieval of abstract from Scopus for
# documents without abstract

get '/review/:rev_id/stage/:stage/complete_empty_abstract_scopus' do |rev_id, stage|
  halt_unless_auth('review_admin')
  @review=SystematicReview[rev_id]
  raise Buhos::NoReviewIdError, rev_id if !@review
  @ars=AnalysisSystematicReview.new(@review)
  result=Result.new
  @cd_wo_abstract=@ars.cd_without_abstract(stage)
  add_message(I18n::t(:Processing_n_canonical_documents, count:@cd_wo_abstract.count))
  @cd_wo_abstract.each do |cd|
    result.add_result(Scopus_Abstract.get_abstract_cd(cd[:id]))
  end
  add_result(result)
  redirect back
end


# Automatic retrieval of abstract from Pubmed for
# documents without abstract
get '/review/:rev_id/stage/:stage/complete_empty_abstract_pubmed' do |rev_id, stage|
  halt_unless_auth('review_admin')
  @review=SystematicReview[rev_id]
  raise Buhos::NoReviewIdError, rev_id if !@review
  @ars=AnalysisSystematicReview.new(@review)
  result=Result.new
  @cd_wo_abstract=@ars.cd_without_abstract(stage)
  add_message(I18n::t(:Processing_n_canonical_documents, count:@cd_wo_abstract.count))
  @cd_wo_abstract.each do |cd|
    result.add_result(PubmedRemote.get_abstract_cd(cd))
  end
  add_result(result)
  redirect back
end



# @!endgroup
