# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'forte_gateway/version'

Gem::Specification.new do |spec|
  spec.name          = "forte_gateway"
  spec.version       = ForteGateway::VERSION
  spec.authors       = ["Yaroslav"]
  spec.email         = ["yarilo2008@gmail.com"]
  spec.summary       = "Forte gateway ruby plugin for active merchant"
  spec.description   = ""
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency 'rspec'
  spec.add_dependency "activemerchant", "~> 1.45.0"
  spec.add_dependency "savon", "2.0"
  spec.add_dependency 'ruby-hmac', '~> 0.4.0'
end
