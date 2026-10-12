# Rate-limit API requests and protect authentication endpoints against brute force.
# Apply per-IP request limits and stricter registration and login throttles.
class Rack::Attack
  # Use Redis for consistent throttling across multiple application instances.
  if ENV["REDIS_URL"].present?
    require "redis"
    Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: ENV["REDIS_URL"])
  end

  # Limit each IP to 300 requests per 5 minutes.
  throttle("requests by ip", limit: 300, period: 5.minutes) do |req|
    req.ip
  end

  # Limit login to 5 attempts per minute per IP and email.
  throttle("logins by ip and email", limit: 5, period: 60.seconds) do |req|
    if req.path == "/api/v1/auth/login" && req.post?
      email = begin
        JSON.parse(req.body.read)["email"].to_s.downcase
      rescue StandardError
        ""
      ensure
        req.body.rewind
      end
      "#{req.ip}:#{email}"
    end
  end

  # Limit registration to 10 accounts per hour per IP.
  throttle("registrations by ip", limit: 10, period: 1.hour) do |req|
    req.ip if req.path == "/api/v1/auth/register" && req.post?
  end

  # Return JSON responses for throttled requests.
  self.throttled_responder = lambda do |request|
    retry_after = (request.env["rack.attack.match_data"] || {})[:period]
    headers = { "Content-Type" => "application/json" }
    headers["Retry-After"] = retry_after.to_s if retry_after
    [429, headers, [{ error: "Terlalu banyak percobaan. Coba lagi sebentar lagi." }.to_json]]
  end
end

ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |_name, _start, _finish, _id, payload|
  Rails.logger.warn("[Rack::Attack] throttled #{payload[:request].ip} on #{payload[:request].path}")
end