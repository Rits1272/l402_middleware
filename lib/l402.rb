# frozen_string_literal: true

require 'macaroons'
require 'lighstorm'
require 'digest'

require 'utils'
require 'constants'
require 'l402_logger'

# The L402 class implements authentication and payment handling using the L402 protocol.
# L402 leverages macaroons for access control and the Lightning Network for payments.
#
# This class provides methods for:
# - Verifying macaroons against predefined caveats and preimages.
# - Generating invoices through the Lightning Network.
# - Creating payment request details, including macaroons and invoices.
class L402
  # Verifies a macaroon using the given caveats, preimage, and root key.
  #
  # @param macaroon [String] the macaroon to verify.
  # @param caveats [Array<String>] the list of caveats to satisfy
  # @param preimage [String] the preimage to validate against the macaroon's identifier.
  # @param root_key [String] the root key used to validate the macaroon.
  # @return [Array<(Boolean, String)>] returns a boolean indicating validity and an error message if invalid.
  def self.verify_l402(macaroon, preimage, config)
    verifier = Macaroon::Verifier.new
    config.caveats.each do |caveat|
      verifier.satisfy_exact(caveat)
    end

    begin
      verifier.verify(
        macaroon: macaroon,
        key: config.root_key
      )
    rescue StandardError => e
      return [false, e.message]
    end

    preimage_hash = Digest::SHA256.hexdigest(preimage)
    get_macaroon_details(macaroon)[:@identifier]

    macaroon_id.to_s == preimage_hash.to_s ? [true, nil] : [false, 'invalid preimage']
  end

  # Generates a payment invoice using the Lightning Network.
  #
  # @param description [String] a description of the invoice.
  # @param amount [Integer] the amount to be paid in millisatoshis.
  # @return [Lighstorm::Lightning::Invoice] the generated invoice object.
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

  # Creates a payment request including a macaroon and an invoice.
  #
  # @param root_key [String] the root key to generate the macaroon.
  # @param caveats [Array<String>] the list of caveats to include in the macaroon.
  # @param amount [Integer] the amount to be paid in millisatoshis.
  # @return [Array<(Macaroon, String)>] returns the macaroon and the payment request as a string.
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
