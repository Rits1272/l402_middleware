# frozen_string_literal: true

require 'spec_helper'
require 'logger'

RSpec.describe L402Logger do
  let(:test_output) { StringIO.new }

  before do
    allow($stdout).to receive(:write) { |msg| test_output.puts(msg) }
    L402Logger.configure(output: test_output)
  end

  after do
    test_output.close
  end

  describe '.logger' do
    it 'returns a logger instance' do
      expect(L402Logger.logger).to be_a(Logger)
    end
  end

  describe '.standalone_logger' do
    it 'creates a standalone logger with the correct formatter' do
      logger = L402Logger.standalone_logger
      expect(logger.level).to eq(Logger::DEBUG)

      # Test custom formatting with the dynamic timestamp
      formatted_message = logger.formatter.call(
        'INFO', Time.now, nil, 'Test message'
      )
      expect(formatted_message).to match(/\[L402_MIDDLEWARE\]::.*::INFO::Test message\n/)
    end
  end

  describe '.configure' do
    it 'configures the logger with a custom output and level' do
      custom_output = StringIO.new
      L402Logger.configure(output: custom_output, level: Logger::ERROR)

      logger = L402Logger.logger
      logger.info('This should not be logged')
      logger.error('This should be logged')

      expect(custom_output.string).not_to include('This should not be logged')
      expect(custom_output.string).to include('This should be logged')
    end
  end

  context 'when Rails is defined' do
    let(:rails_logger) { instance_double(Logger, info: nil) }

    before do
      stub_const('Rails', double(logger: rails_logger))
    end

    it 'uses Rails.logger if Rails is available' do
      L402Logger.configure
      expect(rails_logger).to have_received(:info).with('[L402_MIDDLEWARE] logger initialized')
    end
  end

  context 'when Rails is not defined' do
    it 'defaults to the standalone logger' do
      hide_const('Rails')
      expect(L402Logger.logger).to be_a(Logger)
    end
  end
end

