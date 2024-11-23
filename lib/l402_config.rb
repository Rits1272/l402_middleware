# frozen_string_literal: true

require 'l402_logger'

module L402Middleware
  # The Configuration class handles setup and validation of parameters for L402 middleware.
  class Configuration
    attr_reader :network_type, :root_key, :caveats, :lnd, :lnurl, :invoice, :endpoints

    REQUIRED_NETWORK_KEYS = {
      lnd: %i[address tls_certificate_path macaroon_path],
      lnurl: %i[host]
    }.freeze

    REQUIRED_INVOICE_KEYS = %i[millisatoshis description payable].freeze

    ALLOWED_NETWORK_TYPES = %i[lnd lnurl].freeze
    ALLOWED_PAYABLE_TYPES = %i[once indefinitely].freeze

    MATCH_ALL_ENDPOINTS_REGEX = [%r{.*}]

    def initialize(config = {})
      @network_type = config[:network_type]
      @root_key = config[:root_key]
      @caveats = config[:caveats]
      @lnd = config[:lnd]
      @lnurl = config[:lnurl]
      @invoice = config[:invoice]
      @endpoints = config[:endpoints] || MATCH_ALL_ENDPOINTS_REGEX
    end

    # Validates the configuration to ensure all required parameters are present and valid.
    # @raise [StandardError] Raises an error if validation fails.
    # @return [Boolean] Returns true if the configuration is valid.
    def validate!
      validate_root_key
      validate_caveats
      validate_network_type
      validate_network_config
      validate_invoice

      true
    rescue StandardError => e
      L402Logger.error("Configuration validation error: #{e.message}")
      raise e
    end

    private

    def validate_root_key
      raise 'Missing root key' if blank?(@root_key)
    end

    def validate_caveats
      raise 'Invalid caveats. Must be an Array' unless @caveats.is_a?(Array)
    end

    def validate_network_type
      return if ALLOWED_NETWORK_TYPES.include?(@network_type)

      raise "Invalid network type. Allowed types: #{ALLOWED_NETWORK_TYPES.join(', ')}"
    end

    def validate_network_config
      required_keys = REQUIRED_NETWORK_KEYS[@network_type]
      config = @network_type == :lnd ? @lnd : @lnurl

      validate_required_keys(config, required_keys, "Missing required keys for #{@network_type}")
    end

    def validate_invoice
      raise 'Invalid invoice object. Must be a Hash' unless @invoice.is_a?(Hash)

      validate_required_keys(@invoice, REQUIRED_INVOICE_KEYS, 'Missing required invoice keys')

      payable = @invoice[:payable]&.to_sym
      return if ALLOWED_PAYABLE_TYPES.include?(payable)

      raise "Invalid payable type. Allowed types: #{ALLOWED_PAYABLE_TYPES.join(', ')}"
    end

    def validate_required_keys(hash, keys, error_message)
      missing_keys = keys.select { |key| blank?(hash[key]) }
      return if missing_keys.empty?

      raise "#{error_message}: #{missing_keys.join(', ')}"
    end

    def blank?(value)
      value.to_s.strip.empty?
    end
  end
end

