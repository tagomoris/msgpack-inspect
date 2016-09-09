module MessagePack
  module Inspect
    # Node(Hash)
    # header:  hex (binary)
    # exttype: hex (value)
    # length:  numeric
    # data:    hex
    # value:   object
    # children: (array of Node for array, array of Hash, which has keys of :key and :value for map)

    class Inspector
      FORMATS = [:yaml, :json]

      attr_reader :data

      def initialize(io)
        @io = io
        @data = [] # top level objects
        until io.eof?
          dig(io){|obj| @data << obj }
        end
      end

      def hex(str)
        str.unpack("H*").first
      end

      def node(fmt, header)
        case fmt
        when :fixint, :uint8, :uint16, :uint32, :uint64, :int8, :int16, :int32, :int64
          {format: fmt, header: hex(header), data: nil, value: nil}
        when :fixmap, :map16, :map32
          {format: fmt, header: hex(header), length: nil, children: []}
        when :fixarray, :array16, :array32
          {format: fmt, header: hex(header), length: nil, children: []}
        when :fixstr, :str8, :str16, :str32
          {format: fmt, header: hex(header), length: nil, data: nil, value: nil}
        when :nil
          {format: fmt, header: hex(header), data: hex(header), value: nil}
        when :false
          {format: fmt, header: hex(header), data: hex(header), value: false}
        when :true
          {format: fmt, header: hex(header), data: hex(header), value: true}
        when :bin8, :bin16, :bin32
          {format: fmt, header: hex(header), length: nil, data: nil, value: nil}
        when :ext8, :ext16, :ext32, :fixext1, :fixext2, :fixext4, :fixext8, :fixext16
          {format: fmt, header: hex(header), exttype: nil, length: nil, data: nil} # value will be set if MessagePack is installed
        when :float32, :float64
          {format: fmt, header: hex(header), data: nil, value: nil}
        when :never_used
          {format: fmt, header: hex(header), data: hex(header), error: "msgpack format 'NEVER USED' specified"}
        else
          raise "unknown format specifier: #{fmt}"
        end
      end

      def dump(format)
        case format
        when :yaml
          require 'yaml'
          YAML.dump(@data)
        when :json
          begin
            require 'yajl'
            Yajl::Encoder.encode(@data)
          rescue LoadError
            require 'json'
            JSON.dump(@data)
          end
        else
          raise "unknown format: #{format}"
        end
      end

      def dig(io, &block)
        header = io.read(1).b
        fmt = parse_header(header)
        yield generate(io, fmt, header, node(fmt, header))
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

      def generate_array(io, fmt, header, current)
        length = case fmt
                 when :fixarray
                   header.unpack('C').first & 0x0f
                 when :array16
                   io.read(2).unpack('n').first
                 when :array32
                   io.read(4).unpack('N').first
                 else
                   raise "unknown array fmt #{fmt}"
                 end
        current[:length] = length
        length.times do |i|
          dig(io){|obj| current[:children] << obj }
        end
        current
      end

      def generate_map(io, fmt, header, current)
        length = case fmt
                 when :fixmap
                   header.unpack('C').first & 0x0f
                 when :map16
                   io.read(2).unpack('n').first
                 when :map32
                   io.read(4).unpack('N').first
                 else
                   raise "unknown map fmt #{fmt}"
                 end
        current[:length] = length
        length.times do |i|
          pair = {}
          dig(io){|key| pair[:key] = key }
          dig(io){|value| pair[:value] = value }
          current[:children] << pair
        end
        current
      end

      MAX_INT16 = 2 ** 16
      MAX_INT32 = 2 ** 32
      MAX_INT64 = 2 ** 64

      def generate_int(io, fmt, header, current)
        if fmt == :fixint
          current[:data] = hex(header)
          v = header.unpack('C').first
          if v & 0b11100000 > 0 # negative fixint
            current[:value] = header.unpack('c').first
          else # positive fixint
            current[:value] = header.unpack('C').first
          end
          return current
        end

        case fmt
        when :uint8
          v = io.read(1)
          current[:data] = hex(v)
          current[:value] = v.unpack('C').first
        when :uint16
          v = io.read(2)
          current[:data] = hex(v)
          current[:value] = v.unpack('n').first
        when :uint32
          v = io.read(4)
          current[:data] = hex(v)
          current[:value] = v.unpack('N').first
        when :uint64
          v1 = io.read(4)
          v2 = io.read(4)
          current[:data] = hex(v1) + hex(v2)
          current[:value] = (v1.unpack('N').first << 32) | v2.unpack('N').first
        when :int8
          v = io.read(1)
          current[:data] = hex(v)
          current[:value] = v.unpack('c').first
        when :int16
          v = io.read(1)
          current[:data] = hex(v)
          current[:value] = v.unpack('n').first - MAX_INT16
        when :int32
          v = io.read(2)
          current[:data] = hex(v)
          current[:value] = v.unpack('N').first - MAX_INT32
        when :int64
          v1 = io.read(4)
          v2 = io.read(4)
          current[:data] = hex(v1) + hex(v2)
          current[:value] = (v1.unpack('N').first << 32) | v2.unpack('N').first - MAX_INT64
        else
          raise "unknown int format #{fmt}"
        end
        current
      end

      def generate_float(io, fmt, header, current)
        case fmt
        when :float32
          v = io.read(4)
          current[:data] = hex(v)
          current[:value] = v.unpack('g').first
        when :float64
          v = io.read(8)
          current[:data] = hex(v)
          current[:value] = v.unpack('G').first
        else
          raise "unknown float format #{fmt}"
        end
        current
      end

      def generate_string(io, fmt, header, current)
        length = case fmt
                 when :fixstr
                   header.unpack('C').first & 0b00011111
                 when :str8, :bin8
                   io.read(1).unpack('C').first
                 when :str16, :bin16
                   io.read(2).unpack('n').first
                 when :str32, :bin32
                   io.read(4).unpack('N').first
                 else
                   raise "unknown string format #{fmt}"
                 end
        current[:length] = length
        v = io.read(length)
        current[:data] = hex(v)
        if [:fixstr, :str8, :str16, :str32].include?(fmt)
          begin
            current[:value] = v.encode('UTF-8')
          rescue
            current[:error] = $!.message
          end
        else
          current[:value] = v.b
        end
        current
      end

      begin
        require 'msgpack'
      rescue LoadError
        # ignore
      end
      MSGPACK_LOADED = MessagePack.const_defined?('Unpacker')

      def generate_ext(io, fmt, header, current)
        data = ''.b
        length = case fmt
                 when :fixext1 then 1
                 when :fixext2 then 2
                 when :fixext4 then 4
                 when :fixext8 then 8
                 when :fixext16 then 16
                 when :ext8
                   v = io.read(1)
                   data << v
                   v.unpack('C').first
                 when :ext16
                   v = io.read(2)
                   data << v
                   v.unpack('n').first
                 when :ext32
                   v = io.read(4)
                   data << v
                   v.unpack('N').first
                 else
                   raise "unknown ext format #{fmt}"
                 end
        v = io.read(1)
        data << v
        type = v.unpack('c').first
        current[:length] = length
        current[:exttype] = type
        val = io.read(length)
        data << val
        current[:data] = hex(val)
        if MSGPACK_LOADED
          current[:value] = MessagePack.unpack(val)
        end
        current
      end

      def generate(io, fmt, header, current)
        case fmt
        when :fixarray, :array16, :array32
          generate_array(io, fmt, header, current)
        when :fixmap, :map16, :map32
          generate_map(io, fmt, header, current)
        when :nil, :false, :true, :never_used
          # nothing to do...
        when :fixint, :uint8, :uint16, :uint32, :uint64, :int8, :int16, :int32, :int64
          generate_int(io, fmt, header, current)
        when :float32, :float64
          generate_float(io, fmt, header, current)
        when :fixstr, :str8, :str16, :str32, :bin8, :bin16, :bin32
          generate_string(io, fmt, header, current)
        when :ext8, :ext16, :ext32, :fixext1, :fixext2, :fixext4, :fixext8, :fixext16
          generate_ext(io, fmt, header, current)
        else
          raise "unknown format #{fmt}"
        end

        current
      end
    end
  end
end
