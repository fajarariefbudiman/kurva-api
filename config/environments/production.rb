require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local = false

  # Paksa semua trafik lewat HTTPS — penting karena Railway ada di belakang
  # proxy TLS, dan kita tidak mau token JWT pernah lewat koneksi plain HTTP.
  config.force_ssl = true
  config.assume_ssl = true

  # Railway menangkap log lewat stdout, bukan file.
  config.logger = ActiveSupport::Logger.new($stdout)
    .tap { |logger| logger.formatter = ::Logger::Formatter.new }
    .then { |logger| ActiveSupport::TaggedLogging.new(logger) }
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.log_tags = [:request_id]

  config.active_support.report_deprecations = false

  # Host yang diizinkan mengakses aplikasi ini secara langsung.
  # Railway memberi domain acak *.up.railway.app; tambahkan custom domain
  # di sini kalau kamu pakai domain sendiri nantinya.
  config.hosts << ENV["RAILWAY_PUBLIC_DOMAIN"] if ENV["RAILWAY_PUBLIC_DOMAIN"]
  config.hosts << /.*\.up\.railway\.app\z/
  config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
