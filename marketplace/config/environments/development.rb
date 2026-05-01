require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.cache_classes = false
  config.eager_load = false
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.active_storage.service = :local if config.respond_to?(:active_storage)
  config.active_job.queue_adapter = :sidekiq
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.perform_caching = false
  smtp_password = ENV["RESEND_SMTP_PASSWORD"] || ENV["RESEND_API_KEY"]
  if smtp_password.present?
    smtp_port = ENV.fetch("RESEND_SMTP_PORT", "465").to_i
    smtp_implicit_tls = smtp_port == 465

    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = {
      address: ENV.fetch("RESEND_SMTP_HOST", "smtp.resend.com"),
      port: smtp_port,
      user_name: ENV.fetch("RESEND_SMTP_USERNAME", "resend"),
      password: smtp_password,
      authentication: :plain,
      domain: ENV.fetch("RESEND_SMTP_DOMAIN", "shopproven.com"),
      enable_starttls_auto: !smtp_implicit_tls,
      ssl: smtp_implicit_tls
    }
  else
    config.action_mailer.delivery_method = :test
  end
  config.action_mailer.perform_deliveries = true
  config.action_mailer.default_url_options = { host: "localhost", port: 3000 }
  config.log_level = :debug
end
