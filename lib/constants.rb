# frozen_string_literal: true

L402_HEADER = 'l402'
L402_AUTHORIZATION_HEADER = 'HTTP_AUTHORIZATION'
L402_CHALLENGE_HEADER = 'WWW-Authenticate'

L402_TYPE_PAYMENT_REQUIRED = 'PAYMENT REQUIRED'

L402_ORIGIN = 'L402_MIDDLEWARE'

REQUIRED_CONFIG_KEYS = {
  network_type: nil,
  root_key: nil,
  caveats: nil,
  lighstorm: %i[address tls_certificate_path macaroon_path]
}.freeze

ALLOWED_NETWORK_TYPE = %i[lnd lnurl].freeze
