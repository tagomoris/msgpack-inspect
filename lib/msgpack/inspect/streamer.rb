module MessagePack
  module Inspect
    module Streamer
      def self.get(format)
        case format
        when :yaml
          YAMLStreamer
        when :json
          JSONStreamer
        when :jsonl
          JSONLStreamer
        else
          raise ArgumentError, "unknown format #{format}"
        end
      end
    end

      def to_hash
        basic = {format: @format, header: hex(@header)}
        if @error
          basic[:error] = @error
        end

        case @format
        when :fixint, :uint8, :uint16, :uint32, :uint64, :int8, :int16, :int32, :int64
          basic.merge({data: @data, value: @value})
        when :fixmap, :map16, :map32
          basic.merge({length: @length, children: @children})
        when :fixarray, :array16, :array32
          basic.merge({length: @length, children: @children})
        when :fixstr, :str8, :str16, :str32
          basic.merge({length: @length, data: @data, value: @value})
        when :nil
          basic.merge({data: @data, value: @value})
        when :false
          basic.merge({data: @data, value: @value})
        when :true
          basic.merge({data: @data, value: @value})
        when :bin8, :bin16, :bin32
          basic.merge({length: @length, data: @data, value: @value})
        when :ext8, :ext16, :ext32, :fixext1, :fixext2, :fixext4, :fixext8, :fixext16
          if @value
            {format: @format, header: hex(@header), exttype: @exttype, length: @length, data: @data, value: @value}
          else
            {format: @format, header: hex(@header), exttype: @exttype, length: @length, data: @data}
          end
        when :float32, :float64
          {format: @format, header: hex(@header), data: @data, value: @value}
        when :never_used
          {format: @format, header: hex(@header), data: hex(@header)}
        else
          raise "unknown format specifier: #{@format}"
        end
      end

    module YAMLStreamer
      def indent(head = false)
        if head
          "  " * (@depth - 1) + "- "
        else
          "  " * @depth
        end
      end

      def write(*attrs)
        attrs.each do |attr|
          case attr
          when :format
            puts %!#{indent(@heading)}format: "#{@format.to_s}"!
          when :header
            puts %!#{indent}header: "0x#{hex(@header)}"!
          when :data
            puts %!#{indent}data: "0x#{@data}"!
          when :value
            puts %!#{indent}value: #{@value.inspect}!
          when :length
            puts %!#{indent}length: #{@length}!
          when :exttype
            puts %!#{indent}exttype: #{@exttype}!
          end
        end
      end

      def attributes(io)
        write(:format, :header)

        super

        write(:error) if @error

        case @format
        when :fixint, :uint8, :uint16, :uint32, :uint64, :int8, :int16, :int32, :int64
          write(:data, :value)
        when :fixmap, :map16, :map32
          write(:length)
        when :fixarray, :array16, :array32
          write(:length)
        when :fixstr, :str8, :str16, :str32
          write(:length, :data, :value)
        when :nil
          write(:data, :value)
        when :false
          write(:data, :value)
        when :true
          write(:data, :value)
        when :bin8, :bin16, :bin32
          write(:length, :data, :value)
        when :ext8, :ext16, :ext32, :fixext1, :fixext2, :fixext4, :fixext8, :fixext16
          if @value
            write(:exttype, :length, :data, :value)
          else
            write(:exttype, :length, :data)
          end
        when :float32, :float64
          write(:data, :value)
        when :never_used
          write(:data)
        end
      end

      def elements(&block)
        if @length == 0
          puts %!#{indent}children: []!
          return
        end

        puts %!#{indent}children:!
        super
      end

      def element_key
        puts %!#{indent}  - key:!
        super
      end

      def element_value
        puts %!#{indent}    value:!
        super
      end
    end

    module JSONStreamer
      def attributes(io)
        super
      end

      def elements(&block)
        super
      end

      def element_key
        super
      end

      def element_value
        super
      end
    end

    module JSONLStreamer
      def attributes(io)
        super
      end

      def elements(&block)
        super
      end

      def element_key
        super
      end

      def element_value
        super
      end
    end
  end
end
