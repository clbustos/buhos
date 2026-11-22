helpers do
  def render_registration_form
    haml :registration, layout: :layout_empty, escape_html: true
  end

  def notify_registration_request(registration)
    locale=registration.language
    details={locale: locale}
    if registration.status == 'approved'
      account=registration.user
      return false unless account

      if account.token_password.nil? || account.token_datetime.nil? || account.token_datetime <= Time.now - 30*60
        account.update(token_password: SecureRandom.hex(32), token_datetime: Time.now)
      end
      details[:url]="#{request.base_url}#{url('/reset_link')}?t=#{account.token_password}"
    end
    sent=OutgoingEmail.new.send_email(registration.email,
      I18n.t("registration.#{registration.status}_subject", locale: locale),
      I18n.t("registration.#{registration.status}_body", **details))
    registration.update(notified_at: Time.now) if sent
    sent
  rescue StandardError => error
    $log.error("Registration notification failed for request #{registration.id}: #{error.class}")
    false
  end
end

get '/register' do
  halt 404 unless Buhos::Configuration.self_registration?
  @registration_values={}
  render_registration_form
end

post '/register' do
  halt 404 unless Buhos::Configuration.self_registration?
  @registration_values=%w[name login email].to_h {|field| [field, params[field].to_s.strip]}
  name, login, email=@registration_values.values
  login=login.downcase
  email=email.downcase
  unless name.length.between?(1, 255) && login.match?(/\A[a-z0-9_.-]{1,255}\z/) &&
         email.length <= 255 && email.match?(/\A[^\s@<>]+@[^\s@<>]+\.[^\s@<>]+\z/)
    status 422
    @registration_error=t('registration.invalid_fields')
    return render_registration_form
  end
  if RegistrationRequest.identity_taken?(login, email)
    raise RegistrationRequest::IdentityTaken
  end

  language=I18n.locale.to_s == 'es' ? 'es' : 'en'
  RegistrationRequest.create(name: name, login: login, email: email, language: language, created_at: Time.now)
  add_message(t('registration.submitted'))
  redirect url('/login')
rescue RegistrationRequest::IdentityTaken, Sequel::UniqueConstraintViolation
  status 422
  @registration_error=t('registration.identity_taken')
  render_registration_form
end

get '/admin/registration_requests' do
  halt_unless_auth('user_admin')
  @registration_requests=RegistrationRequest.order(Sequel.desc(:pending), :created_at, :id).all
  haml :'admin/registration_requests', escape_html: true
end

post '/admin/registration_requests/:id' do |id|
  halt_unless_auth('user_admin')
  registration=RegistrationRequest[id]
  halt 404 unless registration

  decision=params['decision']
  halt 400 unless %w[approved rejected retry].include?(decision)
  if decision == 'retry'
    halt 409 if registration.status == 'pending'
  else
    halt 409 unless registration.status == 'pending'
    begin
      registration.decide!(decision)
    rescue RegistrationRequest::AlreadyDecided
      halt 409
    rescue RegistrationRequest::IdentityTaken, Sequel::UniqueConstraintViolation
      add_message(t('registration.identity_taken'), :error)
      redirect url('/admin/registration_requests')
    end
  end
  unless registration.notified_at
    success=notify_registration_request(registration)
    add_message(t(success ? 'registration.notification_sent' : 'registration.notification_failed'), success ? :info : :error)
  end
  redirect url('/admin/registration_requests')
end
