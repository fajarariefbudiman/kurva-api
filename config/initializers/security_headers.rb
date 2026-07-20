# Header keamanan standar untuk setiap response. Ditulis manual (tanpa gem
# tambahan) supaya gampang diaudit dan tidak menambah dependency berat.
class SecurityHeaders
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, body = @app.call(env)

    headers["X-Content-Type-Options"] ||= "nosniff"
    headers["X-Frame-Options"] ||= "DENY"
    headers["X-XSS-Protection"] ||= "1; mode=block"
    headers["Referrer-Policy"] ||= "strict-origin-when-cross-origin"
    headers["Permissions-Policy"] ||= "geolocation=(), camera=(), microphone=()"
    # API murni JSON — tidak pernah menyajikan HTML/JS, jadi CSP boleh ketat.
    headers["Content-Security-Policy"] ||= "default-src 'none'"

    [status, headers, body]
  end
end

Rails.application.config.middleware.use SecurityHeaders
