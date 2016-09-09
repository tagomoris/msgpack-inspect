require 'optparse'
require 'msgpack/inspect'

module MessagePack
  module Inspect
    module Command
      def self.execute(argv)
        format = :yaml

        opts = OptionParser.new
        opts.banner = "Usage: msgpack-inspect [options] FILE"
        opts.separator ""
        opts.separator "Options:"
        opts.separator ""
        opts.on("-f", "--format FORMAT", "output format of inspection result (yaml/json) [default: yaml]") do |v|
          format = v.to_sym
        end
        opts.on("-r", "--require LIB", "ruby file path to require (to load ext type definitions)") do |path|
          require path
        end
        opts.on_tail("-h", "--help", "Show this message") do
          puts opts
          exit
        end
        opts.parse!(argv)

        filename = argv.first
        io = if filename == '-'
               STDIN.binmode
             else
               File.open(filename).binmode
             end
        unless MessagePack::Inspect::FORMATS.include?(format)
          puts opts
          puts "Unsupported format: #{format}"
          exit 1
        end

        puts MessagePack::Inspect.inspect(io).dump(format)
      end
    end
  end
end
