# Encode and decode authentication JWTs.
# JWTs contain a user ID and expire after 30 days by default.
module JsonWebToken
  ALGORITHM = "HS256".freeze

  def self.secret_key
    ENV.fetch("JWT_SECRET") { Rails.application.secret_key_base }
  end

  def self.encode(payload, exp = 30.days.from_now)
    payload = payload.dup
    payload[:exp] = exp.to_i
    JWT.encode(payload, secret_key, ALGORITHM)
  end

  # Return the decoded payload for valid JWTs, otherwise nil.
  def self.decode(token)
    decoded = JWT.decode(token, secret_key, true, algorithm: ALGORITHM)[0]
    HashWithIndifferentAccess.new(decoded)
  rescue JWT::ExpiredSignature, JWT::DecodeError, JWT::VerificationError
    nil
  end
end
