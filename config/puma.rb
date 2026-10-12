max_threads_count = ENV.fetch("RAILS_MAX_THREADS", 5)
min_threads_count = ENV.fetch("RAILS_MIN_THREADS", max_threads_count)
threads min_threads_count, max_threads_count

# Use the PORT environment variable provided by Railway.
port ENV.fetch("PORT", 3000)

workers ENV.fetch("WEB_CONCURRENCY", 1)
preload_app!

environment ENV.fetch("RAILS_ENV", "development")

plugin :tmp_restart
