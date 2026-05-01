Devise.setup do |config|
  config.mailer_sender = Rails.env.production? ? "noreply@shopproven.com" : "onboarding@resend.dev"
  config.secret_key = ENV.fetch("DEVISE_SECRET_KEY", "devise-secret-key-change-me-in-production")
  require "devise/orm/active_record"

  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]
  config.skip_session_storage = [:http_auth]
  config.stretches = Rails.env.test? ? 1 : 12
  config.reconfirmable = true
  config.password_length = 8..128
  config.reset_password_within = 6.hours
  config.sign_out_via = :delete

  config.omniauth :google_oauth2,
                  ENV.fetch("GOOGLE_CLIENT_ID", "replace_me"),
                  ENV.fetch("GOOGLE_CLIENT_SECRET", "replace_me"),
                  scope: "email,profile",
                  prompt: "select_account"
end
