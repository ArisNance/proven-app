require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local = false
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?
  config.force_ssl = ENV.fetch("FORCE_SSL", "true") == "true"
  config.log_level = :info
  config.active_job.queue_adapter = :sidekiq
  config.action_mailer.default_url_options = { host: ENV.fetch("APP_HOST", "example.com") }
  config.hosts << "proven-app-production-e60e.up.railway.app"
  config.hosts << "shopproven.com"
  config.hosts << "www.shopproven.com"
  config.hosts << "marketplace.shopproven.com"
end
