source "https://rubygems.org"

ruby "3.2.2"

# Rails inti, mode API-only (tanpa view/asset pipeline)
gem "rails", "~> 7.1.3"

# Database — Postgres (dipakai juga oleh Railway)
gem "pg", "~> 1.5"

# App server
gem "puma", "~> 6.4"

# Autentikasi
gem "bcrypt", "~> 3.1"          # hash password (has_secure_password)
gem "jwt", "~> 2.8"             # token JWT untuk sesi login

# Middleware keamanan
gem "rack-cors", "~> 2.0"       # CORS, supaya app Flutter boleh akses API
gem "rack-attack", "~> 6.7"     # rate limiting & proteksi brute-force

# Serialisasi JSON response yang rapi & konsisten
gem "blueprinter", "~> 1.0"

# Environment variables dari file .env saat development
gem "dotenv-rails", "~> 3.1", groups: [:development, :test]

# Booting lebih cepat
gem "bootsnap", "~> 1.18", require: false

# Reduces boot times through caching; required in config/boot.rb
group :development, :test do
  gem "rspec-rails", "~> 6.1"
  gem "factory_bot_rails", "~> 6.4"
  gem "faker", "~> 3.3"
end

group :development do
  gem "listen", "~> 3.9"
end

group :test do
  gem "shoulda-matchers", "~> 6.2"
  gem "database_cleaner-active_record", "~> 2.2"
end

# Time zone data untuk Windows/JRuby (aman ditinggal di semua platform)
gem "tzinfo-data", platforms: %i[windows jruby]
