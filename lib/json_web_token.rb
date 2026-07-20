# Encode & decode token JWT yang dipakai untuk autentikasi API.
#
# Token berisi `user_id` dan kedaluwarsa otomatis (default 30 hari) supaya
# user tidak perlu login ulang tiap hari, tapi tetap ada batas waktu kalau
# HP hilang / dicuri.
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

  # Mengembalikan payload (Hash) kalau valid, atau nil kalau token tidak
  # valid / sudah kedaluwarsa / dipalsukan.
  def self.decode(token)
    decoded = JWT.decode(token, secret_key, true, algorithm: ALGORITHM)[0]
    HashWithIndifferentAccess.new(decoded)
  rescue JWT::ExpiredSignature, JWT::DecodeError, JWT::VerificationError
    nil
  end
end
