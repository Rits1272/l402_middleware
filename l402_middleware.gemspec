# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'l402_middleware'
  s.version     = '0.0.1'
  s.summary     = 'L402 middleware for authentication and payment handling'
  s.description = 'A Ruby middleware implementation for the L402 protocol, leveraging macaroons and the Lightning Network for secure authentication and payments.'
  s.authors     = ['Ritik Jain']
  s.email       = 'ritikjain1272@gmail.com'
  s.files       = ['lib/l402_middleware.rb']
  s.homepage    = 'https://rubygems.org/gems/l402_middleware'
  s.license     = 'MIT'

  s.add_runtime_dependency 'google-protobuf', '3.25.4'
  s.add_runtime_dependency 'lighstorm'
  s.add_runtime_dependency 'macaroons'

  s.add_development_dependency 'rspec'
end
