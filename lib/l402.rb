# frozen_string_literal: true

require 'macaroons'
require 'lighstorm'
require 'digest'

require 'utils'
require 'constants'
require 'l402_logger'

# The L402 class provides authentication and payment handling using the L402 protocol.
# It leverages macaroons for access control and the Lightning Network for payments.
#
# This class includes methods to:
# - Verify macaroons against caveats and preimages.
# - Generate Lightning Network invoices.
# - Create payment request details with associated macaroons and invoices.
class L402
  # Verifies the validity of a macaroon against a preimage and predefined caveats.
  #
  # @param macaroon [String] The macaroon string to be verified.
  # @param preimage [String] The preimage to match against the macaroon's identifier.
  # @param config [Object] Configuration containing the root key and caveats.
  # @return [Array(Boolean, String)] Returns a tuple where the first element is a
  #   boolean indicating success, and the second is an error message or nil.
  def self.verify_l402(macaroon, preimage, config)
    mac = Macaroon.new(key: config.root_key, identifier: macaroon, location: L402_ORIGIN)

    verifier = Macaroon::Verifier.new
    config.caveats.each do |caveat|
      verifier.satisfy_exact(caveat)
    end

    begin
      verifier.verify(
        macaroon: mac,
        key: config.root_key
      )
    rescue StandardError => e
      return [false, e.message]
    end

    preimage_hash = Digest::SHA256.hexdigest(preimage)
    macaroon_id = get_macaroon_details(mac)[:@identifier]

    macaroon_id.to_s == preimage_hash.to_s ? [true, nil] : [false, 'invalid preimage']
  end

  # Generates a Lightning Network invoice with the specified description and amount.
  #
  # @param description [String] Description of the payment associated with the invoice.
  # @param amount [Integer] Amount in millisatoshis (msat) to be paid.
  # @return [Hash] Returns a hash representation of the created invoice.
  # @raise [StandardError] Raises an error if invoice generation fails.
  def self.generate_invoice(description, amount)
    Lighstorm::Lightning::Invoice.create(
      description: description,
      amount: { millisatoshis: amount },
      payable: 'once'
    )
  rescue StandardError => e
    L402Logger.info("Unable to generate invoice: #{e.backtrace.join('\n')}")
    raise "Unable to generate invoice: #{e.message}"
  end

  # Creates payment request details, including a macaroon and Lightning Network invoice.
  #
  # @param config [Object] Configuration containing the root key and caveats.
  # @return [Array(Macaroon, Hash)] Returns a tuple with the macaroon and invoice details.
  def self.get_payment_request_details(config)
    invoice = generate_invoice('description', 100).to_h

    payment_hash = invoice[:response][:r_hash].unpack1('H*')

    m = Macaroon.new(key: config.root_key, identifier: payment_hash, location: L402_ORIGIN)

    config.caveats.each do |caveat|
      m.add_first_party_caveat(caveat)
    end

    [m, invoice]
  end
end
