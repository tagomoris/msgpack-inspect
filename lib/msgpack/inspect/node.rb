module MessagePack
  module Inspect
    class Node
      # header:  hex (binary)
      # exttype: hex (value)
      # length:  numeric
      # data:    hex
      # value:   object
      # children: (array of Node for array, array of Hash, which has keys of :key and :value for map)
      attr_accessor :format, :header, :length, :exttype, :data, :value, :children, :error
      attr_accessor :depth, :heading

      FORMATS = [
        :fixint, :uint8, :uint16, :uint32, :uint64, :int8, :int16, :int32, :int64,
        :fixmap, :map16, :map32,
        :fixarray, :array16, :array32,
        :fixstr, :str8, :str16, :str32,
        :nil, :false, :true,
        :bin8, :bin16, :bin32,
        :ext8, :ext16, :ext32, :fixext1, :fixext2, :fixext4, :fixext8, :fixext16,
        :float32, :float64,
        :never_used,
      ]
      ARRAYS = [:fixarray, :array16, :array32]
      MAPS = [:fixmap, :map16, :map32]

      def initialize(format, header)
        raise "unknown format specifier: #{format}" unless FORMATS.include?(format)
        @format = format
        @header = header # call #hex to dump
        @length = @exttype = @data = @value = @children = @error = nil

        case @format
        when :fixmap, :map16, :map32, :fixarray, :array16, :array32
          @children = []
        when :nil
          @data = hex(header)
          @value = nil
        when :false
          @data = hex(header)
          @value = false
        when :true
          @data = hex(header)
          @value = true
        when :never_used
          @data = hex(header)
          @error = "msgpack format 'NEVER USED' specified"
        end
      end

      def hex(str)
        str.unpack("H*").first
      end

      def elements(&block)
        @length.times do |i|
          yield i
        end
      end

      def element_key
        yield
      end

      def element_value
        yield
      end

      def attributes(io)
        # read attributes from io
        case @format
        when :fixarray, :array16, :array32
          attributes_array(io)
        when :fixmap, :map16, :map32
          attributes_map(io)
        when :nil, :false, :true, :never_used
          # nothing to do...
        when :fixint, :uint8, :uint16, :uint32, :uint64, :int8, :int16, :int32, :int64
          attributes_int(io)
        when :float32, :float64
          attributes_float(io)
        when :fixstr, :str8, :str16, :str32, :bin8, :bin16, :bin32
          attributes_string(io)
        when :ext8, :ext16, :ext32, :fixext1, :fixext2, :fixext4, :fixext8, :fixext16
          attributes_ext(io)
        end
      end

      def attributes_array(io)
        @length = case @format
                  when :fixarray
                    @header.unpack('C').first & 0x0f
                  when :array16
                    io.read(2).unpack('n').first
                  when :array32
                    io.read(4).unpack('N').first
                  else
                    raise "unknown array fmt #{@format}"
                  end
      end

      def attributes_map(io)
        @length = case @format
                  when :fixmap
                    @header.unpack('C').first & 0x0f
                  when :map16
                    io.read(2).unpack('n').first
                  when :map32
                    io.read(4).unpack('N').first
                  else
                    raise "unknown map fmt #{@format}"
                  end
      end

      MAX_INT16 = 2 ** 16
      MAX_INT32 = 2 ** 32
      MAX_INT64 = 2 ** 64

      def attributes_int(io)
        if @format == :fixint
          @data = hex(@header)
          v = @header.unpack('C').first
          @value = if v & 0b11100000 > 0 # negative fixint
                     @header.unpack('c').first
                   else # positive fixint
                     @header.unpack('C').first
                   end
          return
        end

        case @format
        when :uint8
          v = io.read(1)
          @data = hex(v)
          @value = v.unpack('C').first
        when :uint16
          v = io.read(2)
          @data = hex(v)
          @value = v.unpack('n').first
        when :uint32
          v = io.read(4)
          @data = hex(v)
          @value = v.unpack('N').first
        when :uint64
          v1 = io.read(4)
          v2 = io.read(4)
          @data = hex(v1) + hex(v2)
          @value = (v1.unpack('N').first << 32) | v2.unpack('N').first
        when :int8
          v = io.read(1)
          @data = hex(v)
          @value = v.unpack('c').first
        when :int16
          v = io.read(2)
          @data = hex(v)
          n = v.unpack('n').first
          @value = if (n & 0x8000) > 0 # negative
                     n - MAX_INT16
                   else
                     n
                   end
        when :int32
          v = io.read(4)
          @data = hex(v)
          n = v.unpack('N').first
          @value = if n & 0x80000000 > 0 # negative
                     n - MAX_INT32
                   else
                     n
                   end
        when :int64
          v1 = io.read(4)
          v2 = io.read(4)
          @data = hex(v1) + hex(v2)
          n = (v1.unpack('N').first << 32) | v2.unpack('N').first
          @value = if n & 0x8000_0000_0000_0000 > 0 # negative
                     n - MAX_INT64
                   else
                     n
                   end
        else
          raise "unknown int format #{@format}"
        end
      end

      def attributes_float(io)
        case @format
        when :float32
          v = io.read(4)
          @data = hex(v)
          @value = v.unpack('g').first
        when :float64
          v = io.read(8)
          @data = hex(v)
          @value = v.unpack('G').first
        else
          raise "unknown float format #{@format}"
        end
      end

      def attributes_string(io)
        @length = case @format
                  when :fixstr
                    @header.unpack('C').first & 0b00011111
                  when :str8, :bin8
                    io.read(1).unpack('C').first
                  when :str16, :bin16
                    io.read(2).unpack('n').first
                  when :str32, :bin32
                    io.read(4).unpack('N').first
                  else
                    raise "unknown string format #{@format}"
                  end
        v = io.read(@length)
        @data = hex(v)
        if [:fixstr, :str8, :str16, :str32].include?(@format)
          begin
            @value = v.force_encoding('UTF-8')
          rescue
            @error = $!.message
          end
        else
          @value = v.b
        end
      end

      MSGPACK_LOADED = MessagePack.const_defined?('Unpacker')

      def attributes_ext(io)
        data = ''.b
        @length = case @format
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
                    raise "unknown ext format #{@format}"
                  end
        v = io.read(1)
        @exttype = v.unpack('c').first
        val = io.read(@length)
        @data = hex(val)
        @value = if MSGPACK_LOADED
                   MessagePack.unpack(val)
                 else
                   nil
                 end
      end

      def is_array?
        ARRAYS.include?(@format)
      end

      def is_map?
        MAPS.include?(@format)
      end

      def <<(child)
        raise "adding child object to non-array object" unless is_array?
        @children << child
      end

      def []=(key, value)
        raise "adding key-value objects to non-map object" unless is_map?
        @children << {key => value}
      end
    end
  end
end
