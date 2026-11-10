helpers do
  def load_public_invitation
    headers 'Cache-Control'=>'no-store', 'Referrer-Policy'=>'no-referrer'
    @invitation=Invitation[token: params['token']]
    halt 404 unless @invitation
    @review=@invitation.systematic_review
    I18n.locale=@invitation.language if %w[es en].include?(@invitation.language)
  end

  def render_public_invitation
    haml :'invitations/respond', layout: :layout_empty, escape_html: false
  end
end

get '/invitation/:token' do
  load_public_invitation
  @login=@invitation.suggested_login if @invitation.decision == 'accepted' && !@invitation.user_id
  render_public_invitation
end

post '/invitation/:token/decision' do
  load_public_invitation
  halt 400 unless %w[accepted rejected].include?(params['decision'])
  @invitation.decide!(params['decision'])
  redirect url("/invitation/#{@invitation.token}")
end

post '/invitation/:token/register' do
  load_public_invitation
  halt 409 unless @invitation.decision == 'accepted' && !@invitation.user_id
  @login=params['login'].to_s.strip
  begin
    @invitation.register!(@login, params['password'].to_s, params['repeat_password'].to_s)
    redirect url("/invitation/#{@invitation.token}")
  rescue Invitation::InvalidRegistration => error
    status 422
    @error=t("invitations.#{error.message}")
    render_public_invitation
  end
end
