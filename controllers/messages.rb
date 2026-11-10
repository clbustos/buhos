# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2025, Claudio Bustos Navarrete
# All rights reserved.
# Licensed BSD 3-Clause License
# See LICENSE file for more information
#

# @!group Systematic review message

# Messages for a systematic review
get '/review/:id/messages' do |id|
  halt_unless_auth('review_view')
  @review=SystematicReview[id]
  raise Buhos::NoReviewIdError, id if !@review
  @mensajes_rs=@review.message_srs_dataset.order(Sequel.desc(:time))
  @usuario=User[session['user_id']]
  @members=@review.group ? @review.group.users_dataset.order(:name, :id).all : []
  haml "systematic_reviews/messages".to_sym , escape_html: false
end

post '/review/:id/messages' do
  halt 403 unless User[session['user_id']] && (auth_to('review_edit') || review_belongs_to(params['id'], session['user_id']))
  halt_unless_auth('message_edit')
  @review=SystematicReview[params['id']]
  raise Buhos::NoReviewIdError, params['id'] unless @review
  @members=@review.group ? @review.group.users_dataset.order(:name, :id).all : []
  @usuario=User[session['user_id']]
  @mensajes_rs=@review.message_srs_dataset.order(Sequel.desc(:time))
  ids=params['user_ids']
  valid_ids=ids.is_a?(Array) && !ids.empty? && ids.all? { |id| id.to_s.match?(/\A[0-9]+\z/) }
  selected_ids=valid_ids ? ids.map(&:to_i).uniq : []
  @selected_ids=selected_ids
  @subject=params['subject'].to_s.strip
  @text=params['text'].to_s.strip

  if !valid_ids || !(selected_ids - @members.map(&:id)).empty?
    status 400
    @error=t('review_messages.invalid_selection')
  elsif @subject.empty? || @subject.length > 255 || @subject.match?(/[\r\n]/) || @text.empty?
    status 400
    @error=t('review_messages.invalid_content')
  else
    recipients=@members.select { |member| selected_ids.include?(member.id) }
    # Include the review context in both the email and the personal message.
    review_url="#{request.base_url}#{url("/review/#{@review.id}/dashboard")}"
    text="#{@review.name}\n\n#{@text}\n\n#{review_url}"
    failed=[]
    mailer=OutgoingEmail.new
    recipients.each do |member|
      Message.create(user_from: session['user_id'], user_to: member.id,
                     subject: @subject, text: text, time: DateTime.now, viewed: false)
      sent=false
      unless member.email.to_s.strip.empty?
        begin
          sent=mailer.send_email(member.email, @subject, text)
        rescue StandardError => error
          $log.error("Review message email failed for user #{member.id}: #{error.class}")
        end
      end
      failed << member.name unless sent
    end
    add_message(t('review_messages.messages_sent', count: recipients.size, email_count: recipients.size - failed.size), :info)
    add_message(escape_html(t('review_messages.emails_failed', names: failed.join(', '))), :error) unless failed.empty?
    redirect url("/review/#{@review.id}/messages")
  end
  haml :'systematic_reviews/messages', escape_html: false
end


# Post a message
post '/review/:id/message/new' do |id|
  halt_unless_auth('message_edit')
  @review=SystematicReview[id]
  raise Buhos::NoReviewIdError, id if !@review
  @user_id=params['user_id']
  return 404 if @review.nil? or @user_id.nil?
  @subject=params['subject']
  @text=params['text']
  $db.transaction(:rollback=>:reraise) do
    id=MessageSr.insert(:systematic_review_id=>id, :user_from=>@user_id, :reply_to=>nil, :time=>DateTime.now(), :subject=>@subject, :text=>@text)
    add_message(t("messages.new_message_for_sr", sr_name:@review[:name]))
  end
  redirect back
end


# Mark a message as seen by a user
post '/message_sr/:ms_id/seen_by/:user_id' do |ms_id, user_id|
  halt_unless_auth('message_edit')

  ms=MessageSrSeen.where(:m_rs_id=>ms_id, :user_id=>user_id)


  unless ms.empty?
    ms.update(:viewed=>true)
  else
    MessageSrSeen.insert(:m_rs_id=>ms_id, :user_id=>user_id,:viewed=>true)
  end
  return 200
end

post '/message/:m_id/seen_by/:user_id' do |m_id, user_id|
  halt_unless_auth('message_edit')
  ms=Message.where(:id=>m_id, :user_to=>user_id)
  if ms
    ms.update(:viewed=>true)
  end
  return 200
end


# Show form to reply a message
post '/message_sr/:ms_id/reply' do |ms_id|
  halt_unless_auth('message_edit')
  ms=MessageSr[ms_id]
  @user_id=params['user_id']
  raise Buhos::NoUserIdError, params['user_id'] unless User[@user_id]
  halt 403 unless is_session_user(@user_id)

  return 404 if ms.nil?
  @subject=params['subject']
  @text=params['text']
  $db.transaction(:rollback=>:reraise) do
    MessageSr.insert(:systematic_review_id=>ms.systematic_review_id, :user_from=>@user_id, :reply_to=>ms.id, :time=>DateTime.now(), :subject=>@subject, :text=>@text)
    add_message(t("messages.add_reply_to", subject: ms.subject))
  end
  redirect back

end

# @!endgroup

# @!group Personal messages

# Send a reply to a message
post '/message_per/:m_id/reply' do |m_id|
  halt_unless_auth('message_edit')
  m_per=Message[m_id]
  @user_id=params['user_id']
  @user=User[@user_id]


  raise Buhos::NoUserIdError, @user_id if !@user
  raise Buhos::NoMessageIdError, m_id     if !m_per

  halt 403 unless is_session_user(@user_id)


  @subject=params['subject'].chomp
  @text=params['text'].chomp
  $db.transaction(:rollback=>:reraise) do
    id=Message.insert(:user_from=>@user_id, :user_to=>m_per.user_from , :reply_to=>m_per.id, :time=>DateTime.now(), :subject=>@subject, :text=>@text, :viewed=>false)
    add_message(t("messages.add_reply_to", subject: m_per.subject))
  end
  redirect back

end

# @!endgroup
