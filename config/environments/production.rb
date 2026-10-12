require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local = false

  # Enforce HTTPS to protect JWTs when running behind the Railway TLS proxy.
  config.force_ssl = true
  config.assume_ssl = true

  # Send logs to stdout for Railway.
  config.logger = ActiveSupport::Logger.new($stdout)
    .tap { |logger| logger.formatter = ::Logger::Formatter.new }
    .then { |logger| ActiveSupport::TaggedLogging.new(logger) }
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.log_tags = [:request_id]

  config.active_support.report_deprecations = false

  # Allow Railway hostnames and any explicitly configured custom domains.
  config.hosts << ENV["RAILWAY_PUBLIC_DOMAIN"] if ENV["RAILWAY_PUBLIC_DOMAIN"]
  config.hosts << /.*\.up\.railway\.app\z/
  config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
