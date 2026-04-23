Rails.application.config.filter_parameters += [
  :password,
  :password_confirmation,
  :token,
  :secret,
  :authorization,
  :api_key,
  :tax_identifier,
  :ein,
  :ssn
]
