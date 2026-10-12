# Enable browser CORS for Flutter Web; native Android and iOS clients do not require CORS.

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
