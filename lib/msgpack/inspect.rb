require "msgpack/inspect/version"
require "msgpack/inspect/inspector"

module MessagePack
  module Inspect
    FORMATS = MessagePack::Inspect::Inspector::FORMATS

    # MessagePack::Inspect.inspect(io).dump(format)
    def self.inspect(io)
      MessagePack::Inspect::Inspector.new(io)
    end
  end
end
