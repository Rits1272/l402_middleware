# frozen_string_literal: true

require 'spec_helper'
require 'macaroons'
require 'base64'
require 'json'
require 'l402_logger'
require 'constants'

RSpec.describe 'L402Middleware Utils' do
  describe '#get_macaroon_details' do
    let(:macaroon) { instance_double('Macaroon') }
    let(:raw_macaroon) { instance_double('RawMacaroon') }

    before do
      allow(macaroon).to receive(:is_a?).with(Macaroon).and_return(true)
      allow(macaroon).to receive(:instance_variable_get).with('@raw_macaroon').and_return(raw_macaroon)
    end

    it 'returns an empty hash if the macaroon is not a Macaroon instance' do
      allow(macaroon).to receive(:is_a?).with(Macaroon).and_return(false)
      expect(get_macaroon_details(macaroon)).to eq({})
    end

    it 'extracts instance variables from the raw macaroon' do
      allow(raw_macaroon).to receive(:instance_variables).and_return(%i[@var1 @var2])
      allow(raw_macaroon).to receive(:instance_variable_get).with(:@var1).and_return('value1')
      allow(raw_macaroon).to receive(:instance_variable_get).with(:@var2).and_return('value2')

      result = get_macaroon_details(macaroon)
      expect(result).to eq({ :@var1 => 'value1', :@var2 => 'value2' })
    end
  end

  describe '#get_macaroon_signature' do
    let(:macaroon) { instance_double('Macaroon') }

    before do
      allow(macaroon).to receive(:serialize).and_return('serialized_macaroon')
    end

    it 'returns the Base64-encoded macaroon' do
      expect(get_macaroon_signature(macaroon)).to eq(Base64.strict_encode64('serialized_macaroon'))
    end
  end

  describe '#sub_l402_header_regex' do
    it 'returns a regex that matches the L402 header size' do
      header_length = L402_HEADER.size + 1
      expected_regex = /^.{#{header_length}}/
      expect(sub_l402_header_regex).to eq(expected_regex)
    end
  end

  describe '#get_payment_header' do
    let(:macaroon) { instance_double('Macaroon') }
    let(:invoice) { { response: { payment_request: 'payment_request_string' } } }

    before do
      allow(macaroon).to receive(:serialize).and_return('serialized_macaroon')
    end

    it 'returns the correct payment header' do
      signature = Base64.strict_encode64('serialized_macaroon')
      expected_header = "#{L402_HEADER} macaroon=#{signature}, invoice=#{invoice[:response][:payment_request]}"
      expect(get_payment_header(macaroon, invoice)).to eq(expected_header)
    end
  end

  describe '#unauthorized_response' do
    it 'returns the unauthorized response JSON' do
      expected_response = {
        status: 'failure',
        status_code: 402,
        error: 'invalid_macaron_or_preimage',
        message: 'The macaroon or preimage provided is incorrect or invalid.'
      }.to_json

      expect(unauthorized_response).to eq(expected_response)
    end
  end

  describe '#request_payment_response' do
    let(:macaroon) { instance_double('Macaroon') }
    let(:invoice) do
      {
        response: { payment_request: 'payment_request_string' },
        result: { description: { memo: 'Test Memo' }, expires_at: '2024-12-31T23:59:59Z', amount: 100 }
      }
    end

    before do
      allow(macaroon).to receive(:serialize).and_return('serialized_macaroon')
    end

    it 'returns the request payment response JSON' do
      signature = Base64.strict_encode64('serialized_macaroon')
      expected_response = {
        status: 'success',
        status_code: 200,
        macaroon: signature,
        payment_request: 'payment_request_string',
        description: 'Test Memo',
        expires_at: '2024-12-31T23:59:59Z',
        amount: 100
      }.to_json

      expect(request_payment_response(macaroon, invoice)).to eq(expected_response)
    end
  end
end
