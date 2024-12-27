# frozen_string_literal: true

require 'spec_helper'
require 'macaroons'
require 'lighstorm'

RSpec.describe L402 do
  let(:config) do
    double('config', root_key: 'root_key', caveats: ['caveat_1', 'caveat_2'])
  end
  let(:macaroon) { 'some_macaroon' }
  let(:preimage) { 'some_preimage' }

  describe '.verify_l402' do
    context 'when macaroon verification is successful' do
      it 'returns true and nil for no error' do
        # Mocks for macaroon verification
        allow(Macaroon::Verifier).to receive(:new).and_return(double(verify: true))
        allow(Macaroon).to receive(:new).and_return(double)

        # Mock get_macaroon_details to return the correct macaroon identifier
        allow(L402).to receive(:get_macaroon_details).and_return({ '@identifier' => Digest::SHA256.hexdigest(preimage) })

        result = L402.verify_l402(macaroon, preimage, config)

        expect(result).to eq([true, nil])
      end
    end

    context 'when macaroon verification fails' do
      it 'returns false and the error message' do
        # Mocks for macaroon verification failure
        allow(Macaroon::Verifier).to receive(:new).and_raise(StandardError, 'verification failed')

        result = L402.verify_l402(macaroon, preimage, config)

        expect(result).to eq([false, 'verification failed'])
      end
    end

    context 'when preimage does not match macaroon identifier' do
      it 'returns false and invalid preimage error' do
        # Mocks for macaroon verification
        allow(Macaroon::Verifier).to receive(:new).and_return(double(verify: true))
        allow(Macaroon).to receive(:new).and_return(double)

        # Mock get_macaroon_details to return a different macaroon identifier
        allow(L402).to receive(:get_macaroon_details).and_return({ '@identifier' => 'different_identifier' })

        result = L402.verify_l402(macaroon, preimage, config)

        expect(result).to eq([false, 'invalid preimage'])
      end
    end
  end

  describe '.generate_invoice' do
    context 'when invoice generation is successful' do
      it 'returns a hash with invoice details' do
        invoice_hash = { response: { r_hash: 'some_hash' } }
        allow(Lighstorm::Lightning::Invoice).to receive(:create).and_return(invoice_hash)

        result = L402.generate_invoice('description', 100)

        expect(result).to eq(invoice_hash)
      end
    end

    context 'when invoice generation fails' do
      it 'raises an error with a message' do
        allow(Lighstorm::Lightning::Invoice).to receive(:create).and_raise(StandardError, 'Invoice error')

        expect { L402.generate_invoice('description', 100) }.to raise_error('Unable to generate invoice: Invoice error')
      end
    end
  end

  describe '.get_payment_request_details' do
    it 'returns a macaroon and invoice hash' do
      invoice_hash = { response: { r_hash: 'some_hash' } }
      allow(L402).to receive(:generate_invoice).and_return(invoice_hash)

      # Mocks for macaroon
      macaroon = instance_double(Macaroon, add_first_party_caveat: nil)
      allow(Macaroon).to receive(:new).and_return(macaroon)

      result = L402.get_payment_request_details(config)

      expect(result).to be_a(Array)
      expect(result.length).to eq(2)
      expect(result[0]).to be_an_instance_of(Macaroon)
      expect(result[1]).to eq(invoice_hash)
    end
  end
end

