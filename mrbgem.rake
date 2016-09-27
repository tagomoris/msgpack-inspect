require_relative 'mrblib/msgpack/inspect/version'

spec = MRuby::Gem::Specification.new('msgpack-inspect') do |spec|
  spec.bins    = ['msgpack-inspect']
  spec.add_dependency 'mruby-io', mgem: 'mruby-io'
  spec.add_dependency 'mruby-print', :core => 'mruby-print'
  spec.add_dependency 'mruby-mtest', :mgem => 'mruby-mtest'
end

spec.license = 'Apache-2.0'
spec.author  = 'Satoshi Tagomori'
spec.summary = 'MessagePack inspection tool written in Ruby'
spec.version = MessagePack::Inspect::VERSION
