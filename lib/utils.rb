# frozen_string_literal: true

require 'macaroons'
require 'base64'
require 'json'

require 'l402_logger'
require 'constants'


# Extracts details from a macaroon object, including its internal variables.
#
# @param macaroon [Macaroon] The macaroon object to extract details from.
# @return [Hash] A hash containing the macaroon's internal details, or an empty hash if the input is not a macaroon.
def get_macaroon_details(macaroon)
  return {} unless macaroon.is_a?(Macaroon)

  raw_macaroon = macaroon.instance_variable_get('@raw_macaroon')

  details = {}

  raw_macaroon.instance_variables.each do |var|
    details[var.to_sym] = raw_macaroon.instance_variable_get(var)
  end

  details
end

# Generates the Base64-encoded signature of a serialized macaroon.
#
# @param macaroon [Macaroon] The macaroon to generate a signature for.
# @return [String] A Base64-encoded string representation of the macaroon's serialized form.
def get_macaroon_signature(macaroon)
  Base64.strict_encode64(macaroon.serialize)
end

# Creates a regex to match and remove the L402 header from a string.
#
# @return [Regexp] A regular expression that matches the L402 header and its whitespace.
def sub_l402_header_regex
  l402_header_size = L402_HEADER.size + 1 # including whitespace
  /^.{#{l402_header_size}}/
end

# Constructs the payment header for an L402-enabled HTTP request.
#
# @param macaroon [Macaroon] The macaroon to include in the header.
# @param invoice [Hash] The invoice details to include in the header.
# @return [String] A formatted string containing the L402 payment header.
#
# @note For more details, refer to the L402 HTTP specification:
#   https://github.com/lightninglabs/L402/blob/master/protocol-specification.md#http-specification
def get_payment_header(macaroon, invoice)
  "#{L402_HEADER} macaroon=#{get_macaroon_signature(macaroon)}, invoice=#{invoice.dig(:response, :payment_request)}"
end

# Generates a standardized JSON response for unauthorized access.
#
# @return [String] A JSON-formatted string representing an unauthorized response.
def unauthorized_response
  {
    :status => "failure",
    :status_code => 402,
    :error => "invalid_macaron_or_preimage",
    :message => "The macaroon or preimage provided is incorrect or invalid.",
  }.to_json
end

# Generates a standardized JSON response containing payment request details.
#
# @param macaroon [Macaroon] The macaroon associated with the payment request.
# @param invoice [Hash] The invoice details to include in the response.
# @return [String] A JSON-formatted string containing payment request details.
def request_payment_response(macaroon, invoice)
  {
    :status => "success",
    :status_code => 200,
    :macaroon => get_macaroon_signature(macaroon),
    :payment_request => invoice.dig(:response, :payment_request),
    :description => invoice.dig(:result, :description, :memo),
    :expires_at => invoice.dig(:result, :expires_at),
    :amount => invoice.dig(:result, :amount)
  }.to_json
end
