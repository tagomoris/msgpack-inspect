module MessagePack
  module Inspect
    class Inspector
      FORMATS = [:yaml, :json, :jsonl, nil] # nil is for test (without stream dump)

      def initialize(io, format = :yaml, opt={})
        # return_values: false, output_io: STDOUT
        @io = io
        @format = format
        @streamer = MessagePack::Inspect::Streamer.get(@format)
        @return_values = opt[:return_values] || false
        @output_io = opt[:output_io] || STDOUT
      end

      def inspect
        data = []
        @streamer.objects(@output_io, 0) do
          i = 0
          begin
            while true
              first_byte = @io.read(1)
              break if first_byte.nil? && @io.eof?
              # breaking out of @streamer.object before writing object-start bytes into STDOUT
              @streamer.object(@output_io, 1, i) do
                obj = dig(1, true, first_byte)
                data << obj if @return_values
              end
              i += 1
            end
          rescue EOFError
            # end of input
          end
        end
        @return_values ? data : nil
      end

      def dig(depth, heading = true, first_byte = nil)
        header_byte = first_byte || @io.read(1)
        # TODO: error handling for header_byte:nil or raised exception
        raise EOFError if header_byte.nil? && @io.eof?

        header = header_byte.b
        fmt = parse_header(header)
        node = MessagePack::Inspect::Node.new(fmt, header)
        node.extend @streamer
        node.io = @output_io
        node.depth = depth # Streamer#depth=
        node.heading = heading

        node.attributes(@io)

        if node.is_array?
          node.elements do |i|
            @streamer.object(@output_io, depth + 2, i) do
              obj = dig(depth + 2) # children -> array
              node << obj if @return_values
            end
          end
        elsif node.is_map?
          node.elements do |i|
            key = node.element_key do
              @streamer.object(@output_io, depth + 3, 0) do
                dig(depth + 3, false) # chilren -> array -> key
              end
            end
            value = node.element_value do
              @streamer.object(@output_io, depth + 3, 0) do
                dig(depth + 3, false) # children -> array -> value
              end
            end
            node[key] = value if @return_values
          end
        end

        node
      end

      HEADER_FIXINT_POSITIVE = Range.new(0x00, 0x7f)
      HEADER_FIXMAP          = Range.new(0x80, 0x8f)
      HEADER_FIXARRAY        = Range.new(0x90, 0x9f)
      HEADER_FIXSTR          = Range.new(0xa0, 0xbf)
      HEADER_FIXINT_NEGATIVE = Range.new(0xe0, 0xff)
      HEADER_NIL        = 0xc0
      HEADER_NEVER_USED = 0xc1
      HEADER_FALSE      = 0xc2
      HEADER_TRUE       = 0xc3
      HEADER_BIN8     = 0xc4
      HEADER_BIN16    = 0xc5
      HEADER_BIN32    = 0xc6
      HEADER_EXT8     = 0xc7
      HEADER_EXT16    = 0xc8
      HEADER_EXT32    = 0xc9
      HEADER_FLOAT32  = 0xca
      HEADER_FLOAT64  = 0xcb
      HEADER_UINT8    = 0xcc
      HEADER_UINT16   = 0xcd
      HEADER_UINT32   = 0xce
      HEADER_UINT64   = 0xcf
      HEADER_INT8     = 0xd0
      HEADER_INT16    = 0xd1
      HEADER_INT32    = 0xd2
      HEADER_INT64    = 0xd3
      HEADER_FIXEXT1  = 0xd4
      HEADER_FIXEXT2  = 0xd5
      HEADER_FIXEXT4  = 0xd6
      HEADER_FIXEXT8  = 0xd7
      HEADER_FIXEXT16 = 0xd8
      HEADER_STR8     = 0xd9
      HEADER_STR16    = 0xda
      HEADER_STR32    = 0xdb
      HEADER_ARRAY16  = 0xdc
      HEADER_ARRAY32  = 0xdd
      HEADER_MAP16    = 0xde
      HEADER_MAP32    = 0xdf

      def parse_header(byte)
        value = byte.unpack('C').first
        case value
        when HEADER_FIXINT_POSITIVE, HEADER_FIXINT_NEGATIVE then :fixint
        when HEADER_FIXMAP   then :fixmap
        when HEADER_FIXARRAY then :fixarray
        when HEADER_FIXSTR   then :fixstr
        when HEADER_NIL      then :nil
        when HEADER_NEVER_USED then :never_used
        when HEADER_FALSE then :false
        when HEADER_TRUE  then :true
        when HEADER_BIN8  then :bin8
        when HEADER_BIN16 then :bin16
        when HEADER_BIN32 then :bin32
        when HEADER_EXT8  then :ext8
        when HEADER_EXT16 then :ext16
        when HEADER_EXT32 then :ext32
        when HEADER_FLOAT32 then :float32
        when HEADER_FLOAT64 then :float64
        when HEADER_UINT8  then :uint8
        when HEADER_UINT16 then :uint16
        when HEADER_UINT32 then :uint32
        when HEADER_UINT64 then :uint64
        when HEADER_INT8   then :int8
        when HEADER_INT16  then :int16
        when HEADER_INT32  then :int32
        when HEADER_INT64  then :int64
        when HEADER_FIXEXT1  then :fixext1
        when HEADER_FIXEXT2  then :fixext2
        when HEADER_FIXEXT4  then :fixext4
        when HEADER_FIXEXT8  then :fixext8
        when HEADER_FIXEXT16 then :fixext16
        when HEADER_STR8  then :str8
        when HEADER_STR16 then :str16
        when HEADER_STR32 then :str32
        when HEADER_ARRAY16 then :array16
        when HEADER_ARRAY32 then :array32
        when HEADER_MAP16 then :map16
        when HEADER_MAP32 then :map32
        else
          raise "never reach here."
        end
      end
    end
  end
end
