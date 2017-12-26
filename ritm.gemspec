lib = File.expand_path('../lib/', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'date'
require 'ritm/version'

Gem::Specification.new do |s|
  s.name        = 'ritm'
  s.version     = Ritm::VERSION
  s.date        = Date.today.to_s
  s.summary     = 'Ruby In The Middle'
  s.description = 'HTTP(S) Intercept Proxy'
  s.authors     = ['Sebastián Tello']
  s.email       = 'argos83+ritm@gmail.com'
  s.files       = Dir['lib/**/*']
  s.homepage    = 'https://github.com/argos83/ritm'
  s.license     = 'Apache License, v2.0'
  s.add_runtime_dependency 'certificate_authority', '~> 0.1.6'
  s.add_runtime_dependency 'dot_hash', '~> 0.5'
  s.add_runtime_dependency 'faraday', '~> 0.13'
  s.add_runtime_dependency 'webrick', '~> 1.3'
  s.add_development_dependency 'httpclient', '~> 2.8'
  s.add_development_dependency 'rake', '~> 12.2'
  s.add_development_dependency 'rspec', '~> 3.7'
  s.add_development_dependency 'rubocop', '~> 0.51'
  s.add_development_dependency 'simplecov', '~> 0.15'
  s.add_development_dependency 'sinatra', '~> 2.0'
  s.add_development_dependency 'sinatra-contrib', '~> 2.0'
  s.add_development_dependency 'thin', '~> 1.7'
end
