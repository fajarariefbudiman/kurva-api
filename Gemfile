source "https://rubygems.org"

ruby "4.0.6"

# Rails API-only framework.
gem "rails", "~> 7.1.3"

# PostgreSQL database for Railway.
gem "pg", "~> 1.5"

# Application server.
gem "puma", "~> 6.4"

# Authentication.
gem "bcrypt", "~> 3.1"          # Password hashing (has_secure_password)
gem "jwt", "~> 2.8"             # JWT authentication tokens

# Security middleware.
gem "rack-cors", "~> 2.0"       # CORS for Flutter Web clients
gem "rack-attack", "~> 6.7"     # Rate limiting and brute-force protection

# Consistent JSON serialization.
gem "blueprinter", "~> 1.0"

# Load local environment variables.
gem "dotenv-rails", "~> 3.1", groups: [:development, :test]

# Improve boot performance.
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

# Time zone support for Windows and JRuby.
gem "tzinfo-data", platforms: %i[windows jruby]
