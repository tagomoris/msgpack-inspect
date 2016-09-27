require_relative 'lib/msgpack/inspect/version' # mrblib/msgpack/inspect/version is symlink to that file

spec = MRuby::Gem::Specification.new('msgpack-inspect') do |spec|
  spec.rbfiles = [
    "mrblib/msgpack/inspect/version.rb",
    "mrblib/msgpack/inspect/node.rb",
    "mrblib/msgpack/inspect/streamer.rb",
    "mrblib/msgpack/inspect/inspector.rb",
    "mrblib/msgpack/inspect.rb",
    "mrblib/msgpack-inspect.rb",
  ]
  spec.bins    = ['msgpack-inspect']
  spec.add_dependency 'mruby-io', mgem: 'mruby-io'
  spec.add_dependency 'mruby-pack', mgem: 'mruby-pack'
  spec.add_dependency 'mruby-print', core: 'mruby-print'
  spec.add_dependency 'mruby-mtest', mgem: 'mruby-mtest'
end

spec.license = 'Apache-2.0'
spec.author  = 'Satoshi Tagomori'
spec.summary = 'MessagePack inspection tool written in Ruby'
spec.version = MessagePack::Inspect::VERSION
