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
      def self.objects(depth)
        yield
      end
      def object(index)
        yield
      end
    end

    module YAMLStreamer
      def self.objects(depth)
        puts "---" if depth == 0
        yield
      end

      def self.object(depth, index)
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
      def self.objects(depth)
        puts "["
        retval = yield
        puts "" # newline after tailing object without comma
        print "  " * depth, "]"
        retval
      end

      def self.object(depth, index)
        if index > 0
          puts ","
        end
        retval = yield
        puts "" # write newline after last attribute of object
        print "    " * (depth - 1), "  }"
        retval
      end

      def initialize(format, header)
        super
        @first_line = true
        @first_kv_pair = true
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
          puts "," unless @first_line
          case attr
          when :format
            print %!#{indent}"format": "#{@format.to_s}"!
          when :header
            print %!#{indent}"header": "0x#{hex(@header)}"!
          when :data
            print %!#{indent}"data": "0x#{@data}"!
          when :value
            if @value.nil?
              print %!#{indent}"value": null!
            else
              print %!#{indent}"value": #{@value.inspect}!
            end
          when :length
            print %!#{indent}"length": #{@length}!
          when :exttype
            print %!#{indent}"exttype": #{@exttype}!
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
        puts ","

        if @length == 0
          print %!#{indent}"children": []!
          return
        end

        puts %!#{indent}"children": [!
        super
        puts "" # newline after last element of array/hash
        print %!#{indent}]!
      end

      def element_key
        if @first_kv_pair
          @first_kv_pair = false
        else
          puts ","
        end
        puts  %!#{indent}    { "key":!
        super
      end

      def element_value
        puts "," # tailing key object
        puts  %!#{indent}      "value":!
        super
        puts "" # newline after value object
        print %!#{indent}    }!
      end
    end

    module JSONLStreamer
      def self.objects(depth)
        yield
      end

      def self.object(depth, index)
        if depth > 1 && index > 0
          print ","
        end
        retval = yield
        print "}"
        puts "" if depth == 1
        retval
      end

      def initialize(format, header)
        super
        @first_obj = true
        @first_kv_pair = true
      end

      def write(*attrs)
        attrs.each do |attr|
          print "," unless @first_obj
          case attr
          when :format
            print %!{"format":"#{@format.to_s}"!
          when :header
            print %!"header":"0x#{hex(@header)}"!
          when :data
            print %!"data":"0x#{@data}"!
          when :value
            if @value.nil?
              print %!"value":null!
            else
              print %!"value":#{@value.inspect}!
            end
          when :length
            print %!"length":#{@length}!
          when :exttype
            print %!"exttype":#{@exttype}!
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
        print ","
        if @length == 0
          print %!"children":[]!
          return
        end

        print %!"children":[!
        super
        print %!]!
      end

      def element_key
        if @first_kv_pair
          @first_kv_pair = false
        else
          print ","
        end
        print  %!{"key":!
        super
      end

      def element_value
        print  %!,"value":!
        super
        print %!}!
      end
    end
  end
end
