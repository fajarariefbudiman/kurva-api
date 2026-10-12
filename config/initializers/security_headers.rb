# Apply auditable security headers without additional dependencies.
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
    # Use a restrictive CSP because this API only serves JSON.
    headers["Content-Security-Policy"] ||= "default-src 'none'"

    [status, headers, body]
  end
end

Rails.application.config.middleware.use SecurityHeaders
