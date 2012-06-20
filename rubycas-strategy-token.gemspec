# -*- encoding: utf-8 -*-
require File.expand_path('../lib/rubycas-strategy-token/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Dmitriy Soltys"]
  gem.email         = ["slotos@gmail.com"]
  gem.description   = %q{Token authenticator (a-la devise token_authenticatable)}
  gem.summary       = %q{Provides ability to authenticate users against database token}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "rubycas-strategy-token"
  gem.require_paths = ["lib"]
  gem.version       = CASServer::Strategy::Token::VERSION

  gem.add_dependency "sequel"
  gem.add_dependency "rubycas-server"
  gem.add_dependency "addressable"

  gem.add_development_dependency "sqlite3"
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "rack-test"
end
