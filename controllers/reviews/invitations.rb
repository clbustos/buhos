before '/review/:id/invitations' do
  halt 403 unless User[session['user_id']] && (auth_to('review_edit') || review_belongs_to(params['id'], session['user_id']))
  @review=SystematicReview[params['id']]
  raise Buhos::NoReviewIdError, params['id'] unless @review
  @invitations=Invitation.where(systematic_review_id: @review.id).order(:id).all
  @language=params.fetch('language', %w[es en].include?(I18n.locale.to_s) ? I18n.locale.to_s : 'en')
  halt 400 unless %w[es en].include?(@language)
end

get '/review/:id/invitations' do
  count=params['count'].to_s
  if params.key?('count')
    if count.match?(/\A\d+\z/) && count.to_i.between?(1, 100)
      @count=count.to_i
      @rows=Array.new(@count) { { 'name'=>'', 'email'=>'' } }
    else
      status 400
      @error=t('invitations.invalid_count')
    end
  end
  haml :'systematic_reviews/invitations', escape_html: false
end

post '/review/:id/invitations' do
  names=params['names']
  emails=params['emails']
  halt 400 unless names.is_a?(Array) && emails.is_a?(Array) && names.size == emails.size && names.size.between?(1, 100)
  @rows=names.zip(emails).map { |name, email| { 'name'=>name.to_s.strip, 'email'=>email.to_s.strip.downcase } }
  @count=@rows.size
  if !@review.group || !(@review.sr_administrator || @review.group.group_administrator)
    @error=t('invitations.invalid_group')
  elsif @rows.any? { |row| row['name'].empty? || row['name'].size > 255 || row['email'].size > 255 || !row['email'].match?(/\A[^\s@<>]+@[^\s@<>]+\.[^\s@<>]+\z/) }
    @error=t('invitations.invalid_rows')
  elsif @rows.map { |row| row['email'] }.uniq.size != @count
    @error=t('invitations.duplicate_email')
  else
    @rows.each do |row|
      previous=Invitation[systematic_review_id: @review.id, email: row['email']]
      if User.where(Sequel.function(:lower, :email)=>row['email']).count > 0
        @error=t('invitations.email_exists')
      elsif previous && (previous.email_sent || previous.decision != 'pending')
        @error=t('invitations.already_invited')
      end
    end
  end
  if @error
    status 400
    return haml :'systematic_reviews/invitations', escape_html: false
  end

  failed=[]
  mailer=OutgoingEmail.new
  @rows.each do |row|
    invitation=Invitation[systematic_review_id: @review.id, email: row['email']]
    invitation ||= Invitation.create(name: row['name'], email: row['email'], systematic_review_id: @review.id,
                                      sender_id: session['user_id'], token: SecureRandom.hex(32), language: @language)
    invitation.update(name: row['name'], language: @language)
    link="#{request.base_url}#{url("/invitation/#{invitation.token}")}"
    text=I18n.t('invitations.email_body', locale: @language, name: invitation.name, review: @review.name, url: link)
    sent=false
    begin
      subject=I18n.t('invitations.email_subject', locale: @language, review: @review.name).gsub(/[\r\n]/, ' ')
      sent=mailer.send_email(invitation.email, subject, text)
    rescue StandardError => error
      $log.error("Invitation email failed for invitation #{invitation.id}: #{error.class}")
    end
    invitation.update(email_sent: true) if sent
    failed << invitation.email unless sent
  end
  add_message(t('invitations.sent_count', count: @count - failed.size), :info)
  add_message(escape_html(t('invitations.failed', emails: failed.join(', '))), :error) unless failed.empty?
  redirect url("/review/#{@review.id}/invitations")
end
