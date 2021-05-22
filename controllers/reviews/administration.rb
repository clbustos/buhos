# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2021, Claudio Bustos Navarrete
# All rights reserved.
# Licensed BSD 3-Clause License
# See LICENSE file for more information



# @!group stages administration
# List of administration interfaces by stage


require 'serrano'
get '/review/:id/administration_stages' do |id|
  halt_unless_auth('review_admin')
  @review=SystematicReview[id]
  raise Buhos::NoReviewIdError, id if !@review
  @ars=AnalysisSystematicReview.new(@review)
  haml %s{systematic_reviews/administration_stages}

end

# Interface to administrate a stage
get '/review/:id/administration/:stage' do |id,stage|
  halt_unless_auth('review_admin')
  @review=SystematicReview[id]

  raise Buhos::NoReviewIdError, id if !@review


  @stage=stage
  @ars=AnalysisSystematicReview.new(@review)
  @cd_without_allocation=@ars.cd_without_allocations(stage)

  @text_decision_cd= Buhos::AnalysisCdDecisions.new(@review, stage)

  @cds_id=@review.cd_id_by_stage(stage)
  @cds=CanonicalDocument.where(:id=>@cds_id)
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
    haml "systematic_reviews/administration_reviews".to_sym
  else
    haml "systematic_reviews/administration_#{stage}".to_sym
  end
end

# Set a resolution for a given pattern

get '/review/:id/stage/:stage/pattern/:patron/resolution/:resolution' do |id,stage,patron_s,resolution|
  halt_unless_auth('review_admin')
  @review=SystematicReview[id]
  raise Buhos::NoReviewIdError, id if !@review

  @ars=AnalysisSystematicReview.new(@review)
  patron=@ars.pattern_from_s(patron_s)
  cds=@ars.cd_from_pattern(stage, patron)

  #$log.info(cds)

  $db.transaction(:rollback=>:reraise) do
    cds.each do |cd_id|
      res=Resolution.where(:systematic_review_id=>id, :canonical_document_id=>cd_id, :stage=>stage)

      if res.empty?
        Resolution.insert(:systematic_review_id=>id, :canonical_document_id=>cd_id, :stage=>stage, :resolution=>resolution, :user_id=>session['user_id'], :commentary=>"Resuelto en forma masiva en #{DateTime.now.to_s}")
      else
        res.update(:resolution=>resolution, :user_id=>session['user_id'], :commentary=>"Actualizado en forma masiva en #{DateTime.now.to_s}")

      end
    end
  end
  add_message(I18n::t("resolution_for_n_documents", resolution:resolution, n:cds.length))
  redirect back
end


# Retrieve information from Crossref for all canonical documents
# approved for a given stage
# TODO: Move this to independent class

get '/review/:rev_id/stage/:stage/generate_crossref_references' do |rev_id,stage|
  halt_unless_auth('review_admin')
  @review=SystematicReview[rev_id]
  @stage=stage
  raise Buhos::NoReviewIdError, id if !@review

  haml "/systematic_reviews/generate_crossref_references".to_sym
end

get '/review/:rev_id/stage/:stage/generate_crossref_references_stream' do |rev_id,stage|

  halt_unless_auth('review_admin')
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

# List of allocations of canonical documents to users
get '/review/:rev_id/administration/:stage/cd_assignations' do |rev_id, stage|
  halt_unless_auth('review_admin')
  @review=SystematicReview[rev_id]
  raise Buhos::NoReviewIdError, rev_id if !@review

  @cds_id=@review.cd_id_by_stage(stage)
  @ars=AnalysisSystematicReview.new(@review)
  @stage=stage
  @cds=CanonicalDocument.where(:id=>@cds_id).order(:author)
  @type="all"
  haml("systematic_reviews/cd_assignations_to_user".to_sym)
end

get '/review/:rev_id/administration/:stage/cd_assignations_excel/:mode' do |rev_id, stage, mode|
  halt_unless_auth('review_admin')
  review=SystematicReview[rev_id]
  raise Buhos::NoReviewIdError, rev_id if !review

  cds_id=review.cd_id_by_stage(stage)
  ars=AnalysisSystematicReview.new(review)
  stage=stage
  cds=CanonicalDocument.where(:id=>cds_id).order(:author)
  users_grupos=review.group_users
  if mode=="save"
    require 'caxlsx'
    package = Axlsx::Package.new
    wb = package.workbook
    blue_cell = wb.styles.add_style  :fg_color => "0000FF", :sz => 14, :alignment => { :horizontal=> :center }
    wrap_text = wb.styles.add_style alignment: { wrap_text: true }
    little_text = wb.styles.add_style
    wb.add_worksheet(:name => t(:Assign)) do |sheet|
      header=["id","reference"]+users_grupos.map {|v| v[:name]}
      sheet.add_row header, :style=> [blue_cell]*(2+users_grupos.count)
      cds.each do |cd|
        row=[cd[:id], cd.ref_apa_6]
        user_allocations=AllocationCd.where(:systematic_review_id=>review[:id], :canonical_document_id=>cd[:id], :stage=>stage ).to_hash(:user_id)
        asignaciones= users_grupos.map {|user|  user_allocations[user[:id]].nil?  ? 0 : 1  }
        sheet.add_row row+asignaciones, style: ([wrap_text]*2)+[nil]*users_grupos.count

      end
      sheet.column_widths *([nil, 30]+ [5]*users_grupos.count)
      sheet.column_widths *([nil, 30]+ [5]*users_grupos.count)
    end

    headers 'Content-Type' => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    headers 'Content-Disposition' => "attachment; filename=cd_assignation_#{rev_id}_#{stage}.xlsx"
    package.to_stream



  else
    return "HOLA"
  end

end

# List of all canonical documents without allocation
# to users


get '/review/:rev_id/administration/:stage/cd_without_allocations' do |rev_id, stage|
  halt_unless_auth('review_admin')
  @review=SystematicReview[rev_id]
  raise Buhos::NoReviewIdError, rev_id if !@review
  @ars=AnalysisSystematicReview.new(@review)

  @stage=stage
  @cds=@ars.cd_without_allocations(stage).order(:author)
  @type="without_allocation"
  haml("systematic_reviews/cd_assignations_to_user".to_sym)
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


# @!endgroup

# @!group Administration of documents without abstract

# List of documents without abstract

get '/review/:rev_id/stage/:stage/complete_empty_abstract_manual' do |rev_id, stage|
  halt_unless_auth('review_admin')
  @review=SystematicReview[rev_id]
  raise Buhos::NoReviewIdError, rev_id if !@review
  @ars=AnalysisSystematicReview.new(@review)
  @stage=stage
  @cd_wo_abstract=@ars.cd_without_abstract(stage)
  haml("systematic_reviews/complete_abstract_manual".to_sym)
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