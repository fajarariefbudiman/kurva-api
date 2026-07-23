require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
# Tidak butuh ActionView / ActionMailer / ActiveStorage untuk API murni ini.

Bundler.require(*Rails.groups)

module KurvaApi
  class Application < Rails::Application
    config.load_defaults 7.1
    config.autoload_lib(ignore: %w[tasks])

    # Ini API-only backend — tidak ada view, session cookie, atau CSRF token.
    config.api_only = true

    # Semua waktu disimpan & ditampilkan dalam WIB, cocok untuk UMKM Indonesia.
    config.time_zone = "Asia/Jakarta"
    config.active_record.default_timezone = :utc

    # Middleware keamanan & rate limiting — dimuat lebih awal supaya
    # request yang mencurigakan diblokir sebelum masuk ke controller.
    config.middleware.use Rack::Attack

    # Pastikan header keamanan standar selalu ada di setiap response
    # (lihat app/controllers/application_controller.rb untuk detailnya).
  end
end
