# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ritm/version'

Gem::Specification.new do |s|
  s.name        = 'ritm'
  s.version     = Ritm::VERSION
  s.date        = Date.today.to_s
  s.summary     = 'Ruby In The Middle'
  s.description = 'HTTP(S) Intercept Proxy'
  s.authors     = ['Sebastián Tello']
  s.email       = 'argos83@gmail.com'
  s.files       = Dir['lib/**/*']
  s.homepage    = 'http://tello.se'
  s.license     = 'MIT'
  s.executables << 'ritm'
  s.add_runtime_dependency 'faraday', '~> 0.9'
  s.add_runtime_dependency 'webrick', '~> 1.3'
  s.add_runtime_dependency 'certificate_authority', '~> 0.1.6'
  s.add_runtime_dependency 'dot_hash', '~> 0.5'
  s.add_development_dependency 'rspec', '~> 3.4'
  s.add_development_dependency 'rubocop', '~> 0.40'
  s.add_development_dependency 'sinatra', '~> 1.4'
  s.add_development_dependency 'thin', '~> 1.6'
  s.add_development_dependency 'rake', '~> 11.1'
end
