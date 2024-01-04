# Buhos
# https://github.com/clbustos/buhos
# Copyright (c) 2016-2024, Claudio Bustos Navarrete
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
  haml "systematic_reviews/messages".to_sym , escape_html: false
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