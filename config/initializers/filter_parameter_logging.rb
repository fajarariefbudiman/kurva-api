# Jangan pernah catat password/token di log server.
Rails.application.config.filter_parameters += [
  :password, :password_confirmation, :token, :authorization
]
