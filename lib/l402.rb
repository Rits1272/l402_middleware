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

  def self.generate_invoice(invoice_config)
    Lighstorm::Lightning::Invoice.create(
      description: invoice_config[:description],
      amount: { millisatoshis: invoice_config[:millisatoshis] },
      payable: invoice_config[:payable]
    )
  rescue StandardError => e
    L402Logger.info("Unable to generate invoice: #{e.backtrace.join('\n')}")
    raise "Unable to generate invoice: #{e.message}"
  end

  def self.get_payment_request_details(config)
    invoice = generate_invoice(config.invoice).to_h

    payment_hash = invoice[:response][:r_hash].unpack1('H*')

    m = Macaroon.new(key: config.root_key, identifier: payment_hash, location: L402_ORIGIN)

    config.caveats.each do |caveat|
      m.add_first_party_caveat(caveat)
    end

    [m, invoice]
  end
end
