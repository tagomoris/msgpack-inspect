# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'msgpack/inspect/version'

Gem::Specification.new do |spec|
  spec.name          = "msgpack-inspect"
  spec.version       = MessagePack::Inspect::VERSION
  spec.authors       = ["TAGOMORI Satoshi"]
  spec.email         = ["tagomoris@gmail.com"]

  spec.summary       = %q{Utility to inspect MessagePack binary}
  spec.description   = %q{This is a command line tool to inspect MessagePack binary, and show the results in YAML or JSON.}
  spec.homepage      = "https://github.com/tagomoris/msgpack-inspect"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.has_rdoc = false
  spec.license = "Apache-2.0"

  spec.add_development_dependency "msgpack", "~> 1.0"
  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "test-unit"
end
