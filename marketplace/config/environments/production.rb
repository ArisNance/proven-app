require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local = false
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?
  config.force_ssl = ENV.fetch("FORCE_SSL", "true") == "true"
  config.log_level = :info
  config.active_job.queue_adapter = :sidekiq
  smtp_port = ENV.fetch("RESEND_SMTP_PORT", "465").to_i
  smtp_implicit_tls = smtp_port == 465

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address: ENV.fetch("RESEND_SMTP_HOST", "smtp.resend.com"),
    port: smtp_port,
    user_name: ENV.fetch("RESEND_SMTP_USERNAME", "resend"),
    password: (ENV["RESEND_SMTP_PASSWORD"] || ENV["RESEND_API_KEY"]),
    authentication: :plain,
    domain: ENV.fetch("RESEND_SMTP_DOMAIN", "shopproven.com"),
    enable_starttls_auto: !smtp_implicit_tls,
    ssl: smtp_implicit_tls
  }
  config.action_mailer.perform_deliveries = true
  config.action_mailer.default_url_options = { host: ENV.fetch("APP_HOST", "example.com") }
  config.hosts << "proven-app-production-e60e.up.railway.app"
  config.hosts << "shopproven.com"
  config.hosts << "www.shopproven.com"
  config.hosts << "marketplace.shopproven.com"
end
