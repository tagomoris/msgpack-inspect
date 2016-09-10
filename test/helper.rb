require 'test/unit'
require 'msgpack'
require 'stringio'

def pack(data)
  MessagePack.pack(data)
end

def io2ins(io)
  MessagePack::Inspect::Inspector.new(io)
end

def str2ins(str)
  MessagePack::Inspect::Inspector.new(StringIO.new(str))
end
