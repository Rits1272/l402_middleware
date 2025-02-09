# frozen_string_literal: true

require 'spec_helper'
require 'l402_logger'

RSpec.describe L402Middleware::Configuration do
  describe '#initialize' do
    it 'sets the attributes correctly' do
      config_data = {
        network_type: :lnd,
        root_key: 'test_root_key',
        caveats: ['test_caveat'],
        lnd: { address: '127.0.0.1', tls_certificate_path: 'path/to/cert', macaroon_path: 'path/to/macaroon' },
        lnurl: { host: 'https://example.com' }
      }

      config = L402Middleware::Configuration.new(config_data)

      expect(config.network_type).to eq(:lnd)
      expect(config.root_key).to eq('test_root_key')
      expect(config.caveats).to eq(['test_caveat'])
      expect(config.lnd).to eq(config_data[:lnd])
      expect(config.lnurl).to eq(config_data[:lnurl])
    end
  end

  describe '#validate!' do
    let(:valid_lnd_config) do
      {
        network_type: :lnd,
        root_key: 'test_root_key',
        caveats: ['test_caveat'],
        invoice: {
          millisatoshis: 100,
          description: 'buy me a coffee :)',
          payable: 'once'
        },
        lnd: { address: '127.0.0.1', tls_certificate_path: 'path/to/cert', macaroon_path: 'path/to/macaroon' }
      }
    end

    let(:valid_lnurl_config) do
      {
        network_type: :lnurl,
        root_key: 'test_root_key',
        caveats: ['test_caveat'],
        invoice: {
          millisatoshis: 100,
          description: 'buy me a coffee :)',
          payable: 'once'
        },
        lnurl: { host: 'https://example.com' }
      }
    end

    context 'with valid configurations' do
      before do
        allow_any_instance_of(L402).to receive(:generate_invoice).and_return(:invoice)
      end

      it 'returns true for valid LND configuration' do
        config = L402Middleware::Configuration.new(valid_lnd_config)
        expect(config.validate!).to be true
      end

      it 'returns true for valid LNURL configuration' do
        config = L402Middleware::Configuration.new(valid_lnurl_config)
        expect(config.validate!).to be true
      end
    end

    context 'with invalid configurations' do
      it 'raises an error for unsupported network type' do
        config_data = valid_lnd_config.merge(network_type: :unsupported_type)
        config = L402Middleware::Configuration.new(config_data)
        expect { config.validate! }.to raise_error(RuntimeError, /Invalid network type.*Allowed types: lnd, lnurl.*/)
      end

      it 'raises an error for missing root key' do
        config_data = valid_lnd_config.merge(root_key: '')
        config = L402Middleware::Configuration.new(config_data)
        expect { config.validate! }.to raise_error('Missing root key')
      end

      it 'raises an error for invalid caveats type' do
        config_data = valid_lnd_config.merge(caveats: 'not_an_array')
        config = L402Middleware::Configuration.new(config_data)
        expect { config.validate! }.to raise_error('Invalid caveats. Must be an Array')
      end

      it 'raises an error for missing LND keys' do
        config_data = valid_lnd_config.merge(lnd: { address: '', tls_certificate_path: 'path/to/cert',
                                                    macaroon_path: '' })
        config = L402Middleware::Configuration.new(config_data)
        expect { config.validate! }.to raise_error('Missing required keys for lnd: address, macaroon_path')
      end

      it 'raises an error for missing LNURL keys' do
        config_data = valid_lnurl_config.merge(lnurl: { host: '' })
        config = L402Middleware::Configuration.new(config_data)
        expect { config.validate! }.to raise_error('Missing required keys for lnurl: host')
      end
    end

    context 'with logger integration' do
      it 'logs validation errors' do
        allow(L402Logger).to receive(:error)
        config_data = valid_lnd_config.merge(network_type: :unsupported_type)
        config = L402Middleware::Configuration.new(config_data)

        expect { config.validate! }.to raise_error(RuntimeError, /Invalid network type.*Allowed types: lnd, lnurl.*/)
        expect(L402Logger).to have_received(:error).with(/config validation failed.*/)
      end
    end
  end
end
