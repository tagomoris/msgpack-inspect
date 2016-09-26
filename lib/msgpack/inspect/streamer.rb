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
        when nil
          NullStreamer
        else
          raise ArgumentError, "unknown format #{format}"
        end
      end
    end

    module NullStreamer
      def self.objects(io, depth)
        yield
      end
      def self.object(io, depth, index)
        yield
      end
    end

    module YAMLStreamer
      def self.objects(io, depth)
        io.puts "---" if depth == 0
        yield
      end

      def self.object(io, depth, index)
        yield
      end

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
            @io.puts %!#{indent(@heading)}format: "#{@format.to_s}"!
          when :header
            @io.puts %!#{indent}header: "0x#{hex(@header)}"!
          when :data
            @io.puts %!#{indent}data: "0x#{@data}"!
          when :value
            if @value.nil?
              @io.puts %!#{indent}value: null!
            else
              @io.puts %!#{indent}value: #{@value.inspect}!
            end
          when :length
            @io.puts %!#{indent}length: #{@length}!
          when :exttype
            @io.puts %!#{indent}exttype: #{@exttype}!
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
          @io.puts %!#{indent}children: []!
          return
        end

        @io.puts %!#{indent}children:!
        super
      end

      def element_key
        @io.puts %!#{indent}  - key:!
        super
      end

      def element_value
        @io.puts %!#{indent}    value:!
        super
      end
    end

    module JSONStreamer
      def self.objects(io, depth)
        io.puts "["
        retval = yield
        io.puts "" # newline after tailing object without comma
        io.print "  " * depth, "]"
        retval
      end

      def self.object(io, depth, index)
        if index > 0
          io.puts ","
        end
        retval = yield
        io.puts "" # write newline after last attribute of object
        io.print "    " * (depth - 1), "  }"
        retval
      end

      def indent(head = @first_line)
        if head
          "    " * (@depth - 1) + "  { "
        else
          "    " * @depth
        end
      end

      def write(*attrs)
        attrs.each do |attr|
          @io.puts "," unless @first_line
          case attr
          when :format
            @io.print %!#{indent}"format": "#{@format.to_s}"!
          when :header
            @io.print %!#{indent}"header": "0x#{hex(@header)}"!
          when :data
            @io.print %!#{indent}"data": "0x#{@data}"!
          when :value
            if @value.nil?
              @io.print %!#{indent}"value": null!
            else
              @io.print %!#{indent}"value": #{@value.inspect}!
            end
          when :length
            @io.print %!#{indent}"length": #{@length}!
          when :exttype
            @io.print %!#{indent}"exttype": #{@exttype}!
          end
          @first_line = false
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
        @io.puts ","

        if @length == 0
          @io.print %!#{indent}"children": []!
          return
        end

        @io.puts %!#{indent}"children": [!
        super
        @io.puts "" # newline after last element of array/hash
        @io.print %!#{indent}]!
      end

      def element_key
        if @first_kv_pair
          @first_kv_pair = false
        else
          @io.puts ","
        end
        @io.puts  %!#{indent}    { "key":!
        super
      end

      def element_value
        @io.puts "," # tailing key object
        @io.puts  %!#{indent}      "value":!
        super
        @io.puts "" # newline after value object
        @io.print %!#{indent}    }!
      end
    end

    module JSONLStreamer
      def self.objects(io, depth)
        yield
      end

      def self.object(io, depth, index)
        if depth > 1 && index > 0
          io.print ","
        end
        retval = yield
        io.print "}"
        io.puts "" if depth == 1
        retval
      end

      def write(*attrs)
        attrs.each do |attr|
          @io.print "," unless @first_obj
          case attr
          when :format
            @io.print %!{"format":"#{@format.to_s}"!
          when :header
            @io.print %!"header":"0x#{hex(@header)}"!
          when :data
            @io.print %!"data":"0x#{@data}"!
          when :value
            if @value.nil?
              @io.print %!"value":null!
            else
              @io.print %!"value":#{@value.inspect}!
            end
          when :length
            @io.print %!"length":#{@length}!
          when :exttype
            @io.print %!"exttype":#{@exttype}!
          end
          @first_obj = false
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
        @io.print ","
        if @length == 0
          @io.print %!"children":[]!
          return
        end

        @io.print %!"children":[!
        super
        @io.print %!]!
      end

      def element_key
        if @first_kv_pair
          @first_kv_pair = false
        else
          @io.print ","
        end
        @io.print  %!{"key":!
        super
      end

      def element_value
        @io.print  %!,"value":!
        super
        @io.print %!}!
      end
    end
  end
end
