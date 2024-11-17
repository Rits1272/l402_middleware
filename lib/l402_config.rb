# frozen_string_literal: true

require 'l402_logger'

module L402Middleware
  class Configuration
    attr_accessor :network_type, :root_key, :caveats, :lnd, :lnurl

    REQUIRED_KEYS = {
      lnd: %i[address tls_certificate_path macaroon_path],
      lnurl: %i[host],
      network_type: %i[]
    }.freeze

    ALLOWED_NETWORK_TYPES = %i[lnd lnurl].freeze

    def initialize(config = {})
      @network_type = config[:network_type]
      @root_key = config[:root_key]
      @caveats = config[:caveats]
      @lnd = config[:lnd]
      @lnurl = config[:lnurl]
    end

    def validate!
      unless ALLOWED_NETWORK_TYPES.include?(@network_type)
        raise "Invalid network type. Allowed types: #{ALLOWED_NETWORK_TYPES.join(',')}"
      end

      required_keys = REQUIRED_KEYS[network_type]
      required_obj = @network_type == :lnd ? @lnd : @lnurl
      missing_keys = required_keys.select { |key| required_obj.dig(key).to_s.strip.empty? }
      raise "Missing required keys for #{network_type}: #{missing_keys.join(', ')}" unless missing_keys.empty?

      raise 'Missing root key' if @root_key.to_s.strip.empty?
      raise 'Invalid caveats. Must be an Array' unless @caveats.is_a?(Array)

      true
    rescue StandardError => e
      L402Logger.error("Configuration validation error: #{e.message}")
      raise e
    end
  end
end
