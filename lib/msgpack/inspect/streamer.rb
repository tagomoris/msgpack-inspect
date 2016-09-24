module MessagePack
  module Inspect
    module Streamer
      def self.get(format)
        case format
        when :yaml
        when :json_pretty
        when :json
        else
          raise ArgumentError, "unknown format #{format}"
        end
      end
    end
  end
end
