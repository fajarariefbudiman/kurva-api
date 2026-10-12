require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
# API-only application does not need view, mailer, or storage frameworks.

Bundler.require(*Rails.groups)

module KurvaApi
  class Application < Rails::Application
    config.load_defaults 7.1
    config.autoload_lib(ignore: %w[tasks])

    # Use API-only mode without browser sessions or CSRF tokens.
    config.api_only = true

    # Use Western Indonesian Time (WIB) for application timestamps.
    config.time_zone = "Asia/Jakarta"
    config.active_record.default_timezone = :utc

    # Load security and rate-limiting middleware before request handling.
    config.middleware.use Rack::Attack

    # Apply standard security response headers.
  end
end
