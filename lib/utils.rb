# frozen_string_literal: true

require 'macaroons'
require 'json'
require 'l402_logger'
require 'base64'

# Retrieves the details of a macaroon by accessing its instance variables.
#
# This method extracts the instance variables of the provided macaroon's internal
# `@raw_macaroon` object and returns them as a hash, where the keys are the names of
# the instance variables (as symbols) and the values are the corresponding values.
#
# @param macaroon [Macaroon] the macaroon object from which details are extracted.
# @return [Hash] a hash containing the instance variable names (as symbols) and their values.
def get_macaroon_details(macaroon)
  return {} unless macaroon.is_a?(Macaroon)

  raw_macaroon = macaroon.instance_variable_get('@raw_macaroon')

  details = {}

  raw_macaroon.instance_variables.each do |var|
    details[var.to_sym] = raw_macaroon.instance_variable_get(var)
  end

  details
end

def get_macaroon_signature(macaroon)
  Base64.encode64(macaroon.serialize)
end

# https://github.com/lightninglabs/L402/blob/master/protocol-specification.md#http-specification
def get_payment_header(macaroon, invoice)
  "#{L402_HEADER} macaroon=#{get_macaroon_signature(macaroon)}, invoice=#{invoice.dig(:response, :payment_request)}"
end

def unauthorized_response
  {
    :status => "failure",
    :status_code => 402,
    :error => "invalid_macaron_or_preimage",
    :message => "The macaroon or preimage provided is incorrect or invalid.",
  }.to_json
end

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
