# CORS — dibutuhkan supaya app Flutter (web) atau tools seperti Postman
# dari domain/origin lain boleh memanggil API ini. Untuk Flutter mobile
# (Android/iOS) sebenarnya CORS tidak berlaku (itu aturan browser), tapi
# kita tetap aktifkan untuk mendukung Flutter Web & testing dari browser.

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch("CORS_ALLOWED_ORIGINS", "*").split(",").map(&:strip)

    resource "/api/*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      expose: ["Authorization"],
      max_age: 600
  end
end
