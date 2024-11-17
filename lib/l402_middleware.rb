# frozen_string_literal: true

require 'base64'
require 'l402'
require 'l402_logger'
require 'l402_config'
require 'utils'
require 'constants'

module L402Middleware
  class << self
    attr_accessor :configuration
  end

  class Middleware
    def initialize(app, config = nil)
      @app = app
      @config = L402Middleware::Configuration.new(config || default_config)

      @config.validate!

      verify_connect
    end

    def call(env)
      # L402Logger.debug("Processing request with env: #{env.to_h}")

      token = extract_auth_token(env)
      return allow_request(env) if valid_l402_token?(token)
        
      is_unauthorized = env[L402_AUTHORIZATION_HEADER].present? 

      invoke_payment(is_unauthorized)
    end

    private

    def default_config
      if defined?(Rails)
        config = Rails.configuration.try(:l402_middleware)
        unless config
          raise 'Rails configuration for L402Middleware is missing. Please pass config along with the L402Middleware'
        end

        config
      else
        unless L402Middleware.configuration
          raise 'Configuration required for standalone mode. Use L402Middleware.configuration to set it.'
        end

        L402Middleware.configuration
      end
    end

    def extract_auth_token(env)
      auth_header = env[L402_AUTHORIZATION_HEADER]
      auth_header&.strip
    end

    # Example token: L402 AGIAJEemVQUTEyNCR0exk7ek90Cg==:1234abcd1234abcd1234abcd
    def valid_l402_token?(token)
      return false unless token.to_s.downcase.start_with?("#{L402_HEADER} ")

      token = token.sub("#{L402_HEADER} ", '')
      macaroon_part, preimage = token.split(':', 2)

      return false if macaroon_part.blank? || preimage.blank?

      macaroons = macaroon_part.split(',')

      macaroons.any? do |macaroon|
        decoded_macaroon = Base64.decode64(macaroon)
        L402.verify_l402(decoded_macaroon, preimage, @config)
      rescue StandardError => e
        L402Logger.error("Error verifying macaroon: #{e.message}")
        false
      end
    end

    def allow_request(env)
      @status, @headers, @response = @app.call(env)
      [@status, @headers, @response]
    end

    def invoke_payment(is_unauthorized = false)
      macaroon, invoice = L402.get_payment_request_details(@config)

      status = 402
      header = {
        'Content-Type' => 'application/json',
        L402_CHALLENGE_HEADER => get_payment_header(macaroon, invoice)
      }
      response = is_unauthorized ? unauthorized_response : request_payment_response(macaroon, invoice)

      [status, header, [response]]
    end

    def verify_connect
      case @config.network_type
      when :lnd
        connect_to_lnd
      when :lnurl
        connect_to_lnurl
      else
        raise "Unsupported network type: #{@config.network_type}"
      end
    end

    def connect_to_lnd
      lnd_config = @config.lnd

      begin
        Lighstorm.connect!(
          address: lnd_config[:address],
          certificate_path: lnd_config[:tls_certificate_path],
          macaroon_path: lnd_config[:macaroon_path]
        )
        L402Logger.info('Successfully connected to LND network')
      rescue StandardError => e
        L402Logger.error("Failed to connect to LND: #{e.message}\n#{e.backtrace.join("\n")}")
        raise "Unable to establish connection with Lightning network: #{e.message}"
      end
    end

    # Placeholder method
    def connect_to_lnurl
      @config.lnurl
      raise 'lnurl to be supported with this middeware yet'
    end
  end
end
