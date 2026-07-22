# Rack::Attack — rate limiting & proteksi brute-force.
#
# Dengan ini:
#  - Tiap IP dibatasi jumlah requestnya secara umum (anti-spam / anti-DoS)
#  - Percobaan login & register dibatasi lebih ketat (anti brute-force
#    password & anti pembuatan akun massal)
class Rack::Attack
  # Cache throttle disimpan di memory Rails secara default. Untuk deployment
  # dengan banyak instance/dyno, arahkan ke Redis lewat REDIS_URL supaya
  # limit-nya konsisten di semua instance.
  if ENV["REDIS_URL"].present?
    require "redis"
    Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: ENV["REDIS_URL"])
  end

  # ── Batas umum: maksimal 300 request / 5 menit per IP ──────────────────
  throttle("requests by ip", limit: 300, period: 5.minutes) do |req|
    req.ip
  end

  # ── Login: maksimal 5 percobaan / menit per kombinasi IP + email ───────
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

  # ── Register: maksimal 10 akun baru / jam per IP ────────────────────────
  throttle("registrations by ip", limit: 10, period: 1.hour) do |req|
    req.ip if req.path == "/api/v1/auth/register" && req.post?
  end

  # Response standar saat kena limit — JSON, bukan HTML, karena ini API.
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