require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module ProvenMarketplace
  class Application < Rails::Application
    config.load_defaults 7.1
    config.time_zone = "UTC"
    config.active_job.queue_adapter = :sidekiq
    config.autoload_lib(ignore: %w[assets tasks])
    config.exceptions_app = routes
  end
end
