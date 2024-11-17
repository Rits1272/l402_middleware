# frozen_string_literal: true

require 'logger'

module L402Logger
  class << self
    def logger
      @logger ||= create_logger
    end

    def create_logger
      defined?(Rails) ? Rails.logger : standalone_logger
    end

    def standalone_logger
      logger = Logger.new($stdout)
      logger.level = Logger::DEBUG

      logger.formatter = proc do |severity, timestamp, _progname, msg|
        "#{timestamp}::[L402_MIDDLEWARE - #{severity}]::#{msg}\n"
      end

      logger
    end

    def configure(output: nil, level: Logger::DEBUG)
      if defined?(Rails) && Rails.logger
        Rails.logger.info("[L402_MIDDLEWARE] logger initialized")
      else
        @logger = Logger.new(output || $stdout)
        @logger.level = level
      end
    end

    %i[debug info warn error fatal unknown].each do |method|
      define_method(method) do |message|
        logger.send(method, message)
      end
    end
  end

end
