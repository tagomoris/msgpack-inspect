module MessagePack
  module Inspect
    FORMATS = MessagePack::Inspect::Inspector::FORMATS

    def self.inspect(io, format)
      MessagePack::Inspect::Inspector.new(io, format).inspect
    end
  end
end
