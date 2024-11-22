# frozen_string_literal: true

require File.join(File.dirname(__FILE__), 'lib/version')

Gem::Specification.new do |s|
  s.name        = 'l402_middleware'
  s.version     = L402Middleware::VERSION
  s.summary     = 'L402 middleware for authentication and payment handling'
  s.description = 'A Ruby middleware implementation for the L402 protocol, leveraging macaroons and the Lightning Network for secure authentication and payments.'
  s.authors     = ['Ritik Jain']
  s.email       = 'ritikjain1272@gmail.com'
  s.files       = ['lib/l402_middleware.rb']
  s.homepage    = 'https://rubygems.org/gems/l402_middleware'
  s.license     = 'MIT'

  s.metadata["source_code_uri"] = "https://github.com/rits1272/l402_middleware"

  s.add_runtime_dependency 'google-protobuf', '3.25.4'
  s.add_runtime_dependency 'lighstorm'
  s.add_runtime_dependency 'macaroons'

  s.add_development_dependency 'rspec'
end
