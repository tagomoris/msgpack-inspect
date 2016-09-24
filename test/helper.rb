require 'test/unit'
require 'msgpack'
require 'stringio'

require 'msgpack/inspect/node'
require 'msgpack/inspect/inspector'
# TODO: require streamer

def pack(data)
  MessagePack.pack(data)
end

def io2data(io)
  MessagePack::Inspect::Inspector.new(io, nil, return_values: true).inspect
end

def str2data(str)
  MessagePack::Inspect::Inspector.new(StringIO.new(str), nil, return_values: true).inspect
end
