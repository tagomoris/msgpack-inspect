require 'helper'
require 'tempfile'

class MessagePackInspectInspectorTest < ::Test::Unit::TestCase
  sub_test_case 'basic msgpack formats' do
    test 'true, false, nil, never_used' do
      str = [
        pack(true),
        pack(true),
        pack(false),
        pack(nil),
        "\xc1".b,
      ].join
      data = str2data(str)
      assert_equal 5, data.size
      assert_equal :true, data[0].format
      assert_equal true, data[0].value
      assert_equal :true, data[1].format
      assert_equal true, data[1].value
      assert_equal :false, data[2].format
      assert_equal false, data[2].value
      assert_equal :nil, data[3].format
      assert_equal nil, data[3].value
      assert_equal :never_used, data[4].format
      assert_equal "msgpack format 'NEVER USED' specified", data[4].error
    end

    data(
      'zero' => [0, :fixint, "\x00".b],
      'one'  => [1, :fixint, "\x01".b],
      'max'  => [127, :fixint, "\x7f".b],
    )
    test 'positive fixnum' do |results|
      num, fmt, str = results
      data = str2data(str)
      assert_equal 1, data.size
      assert_equal fmt, data[0].format
      assert_equal num, data[0].value
    end

    data(
      '-1' => [-1, :fixint, "\xff".b],
      '-32' => [-32, :fixint, "\xe0".b],
    )
    test 'negative fixnum' do |results|
      num, fmt, str = results
      data = str2data(str)
      assert_equal 1, data.size
      assert_equal fmt, data[0].format
      assert_equal num, data[0].value
    end

    data(
      '8 zero'  => [0,   :uint8, "\xcc\x00".b],
      '8 small' => [128, :uint8, "\xcc\x80".b],
      '8 big'   => [255, :uint8, "\xcc\xff".b],
      '16 zero' => [0,     :uint16, "\xcd\x00\x00".b],
      '16 smal' => [256,   :uint16, "\xcd\x01\x00".b],
      '16 big'  => [65535, :uint16, "\xcd\xff\xff".b],
      '32 zero' => [0,          :uint32, "\xce\x00\x00\x00\x00".b],
      '32 smal' => [65536,      :uint32, "\xce\x00\x01\x00\x00".b],
      '32 big'  => [4294967295, :uint32, "\xce\xff\xff\xff\xff".b],
      '64 zero' => [0,         :uint64, "\xcf\x00\x00\x00\x00\x00\x00\x00\x00".b],
      '64 smal' => [(2**32),   :uint64, "\xcf\x00\x00\x00\x01\x00\x00\x00\x00".b],
      '64 big'  => [(2**64-1), :uint64, "\xcf\xff\xff\xff\xff\xff\xff\xff\xff".b],
    )
    test 'uint family' do |results|
      num, fmt, str = results
      data = str2data(str)
      assert_equal 1, data.size
      assert_equal fmt, data[0].format
      assert_equal num, data[0].value
    end

    data(
      '8 0'   => [0, :int8, "\xd0\x00".b],
      '8 1'   => [1, :int8, "\xd0\x01".b],
      '8 -1'  => [-1, :int8, "\xd0\xff".b],
      '8 pos' => [127, :int8, "\xd0\x7f".b],
      '8 neg' => [-128, :int8, "\xd0\x80".b],
      '16 0'   => [0,      :int16, "\xd1\x00\x00".b],
      '16 1'   => [1,      :int16, "\xd1\x00\x01".b],
      '16 -1'  => [-1,     :int16, "\xd1\xff\xff".b],
      '16 pos' => [32767,  :int16, "\xd1\x7f\xff".b],
      '16 neg' => [-32768, :int16, "\xd1\x80\x00".b],
      '32 0'   => [0,          :int32, "\xd2\x00\x00\x00\x00".b],
      '32 1'   => [1,          :int32, "\xd2\x00\x00\x00\x01".b],
      '32 -1'  => [-1,         :int32, "\xd2\xff\xff\xff\xff".b],
      '32 pos' => [(2**31-1),  :int32, "\xd2\x7f\xff\xff\xff".b],
      '32 neg' => [-1*(2**31), :int32, "\xd2\x80\x00\x00\x00".b],
      '64 0'   => [0,          :int64, "\xd3\x00\x00\x00\x00\x00\x00\x00\x00".b],
      '64 1'   => [1,          :int64, "\xd3\x00\x00\x00\x00\x00\x00\x00\x01".b],
      '64 -1'  => [-1,         :int64, "\xd3\xff\xff\xff\xff\xff\xff\xff\xff".b],
      '64 pos' => [(2**63-1),  :int64, "\xd3\x7f\xff\xff\xff\xff\xff\xff\xff".b],
      '64 neg' => [-1*(2**63), :int64, "\xd3\x80\x00\x00\x00\x00\x00\x00\x00".b],
    )
    test 'int family' do |results|
      num, fmt, str = results
      data = str2data(str)
      assert_equal 1, data.size
      assert_equal fmt, data[0].format
      assert_equal num, data[0].value
    end

    # 32-bit single precision floating point number
    # 1 bit(sign), 8bits(exponent), 23bits(fraction)
    # 64-bit double precision floating point number
    # 1 bit(sign), 11bits(exponent), 52bits(fraction)
    data(
      '32 0'   => [->(v){ v.zero? }, :float32, "\xca\x00\x00\x00\x00".b],
      '32 NaN' => [->(v){ v.nan? },  :float32, "\xca\xff\xff\xff\xff".b],
      '32 Inf' => [->(v){ v.infinite? }, :float32, "\xca\x7f\x80\x00\x00".b],
      # example are from https://en.wikipedia.org/wiki/Single-precision_floating-point_format
      '32 1.0' => [1.0, :float32, "\xca\x3f\x80\x00\x00".b],
      '32 -0.375' => [-0.375, :float32, "\xca\xbe\xc0\x00\x00".b],
      '64 0'   => [->(v){ v.zero? },     :float64, "\xcb\x00\x00\x00\x00\x00\x00\x00\x00".b],
      '64 NaN' => [->(v){ v.nan? },      :float64, "\xcb\xff\xff\xff\xff\xff\xff\xff\xff".b],
      # 0b 0 00000000000
      # 0b 0 11111111111 00000...
      # 0b 01111111_11110000
      '64 Inf' => [->(v){ v.infinite? }, :float64, "\xcb\x7f\xf0\x00\x00\x00\x00\x00\x00".b],
      # https://en.wikipedia.org/wiki/Double-precision_floating-point_format
      '64 1.0' => [1.0,   :float64, "\xcb\x3f\xf0\x00\x00\x00\x00\x00\x00".b],
      '64 -2.0' => [-2.0, :float64, "\xcb\xc0\x00\x00\x00\x00\x00\x00\x00".b],
      '64 1.00...' => [1.0000000000000004, :float64, "\xcb\x3f\xf0\x00\x00\x00\x00\x00\x02".b],
    )
    test 'float' do |results|
      proc, fmt, str = results
      data = str2data(str)
      assert_equal 1, data.size
      assert_equal fmt, data[0].format
      if proc.is_a?(Proc)
        assert proc.call(data[0].value)
      else
        num = proc
        assert_equal num, data[0].value
      end
    end

    data(
      'fixstr blank' => [0, '', :fixstr, "\xa0".b],
      'fixstr a char' => [1, 'a', :fixstr, ("\xa1" + "a").b],
      'fixstr chars'  => [10, '0123456789', :fixstr, ("\xaa" + "0123456789").b],
      'fixstr maxlen' => [31, 'a' * 31, :fixstr, ("\xbf" + "a" * 31).b],
      'fixstr unicode' => [9, 'あああ', :fixstr, ("\xa9" + 'あああ').b],
      'str8 blank' => [0, '', :str8, "\xd9\x00".b],
      'str8 a char' => [1, 'a', :str8, ("\xd9\x01" + "a").b],
      'str8 maxlen' => [0xff, 'a' * 0xff, :str8, ("\xd9\xff" + "a" * 0xff).b],
      'str16 blank' => [0, '', :str16, "\xda\x00\x00".b],
      'str16 a char' => [1, 'a', :str16, ("\xda\x00\x01" + "a").b],
      'str32 blank' => [0, '', :str32, "\xdb\x00\x00\x00\x00".b],
      'str32 a char' => [1, 'a', :str32, ("\xdb\x00\x00\x00\x01" + "a").b],
    )
    test 'str' do |results|
      length, string, fmt, str = results
      data = str2data(str)
      assert_equal 1, data.size
      assert_equal fmt, data[0].format
      assert_equal length, data[0].length
      assert_equal string, data[0].value
      assert_equal 'UTF-8', data[0].value.encoding.name
    end

    data(
      'bin8 blank'   => [0, ''.b, :bin8, "\xc4\x00".b],
      'bin8 a char'  => [1, 'a'.b, :bin8, ("\xc4\x01" + "a").b],
      'bin8 maxlen'  => [0xff, ('a' * 0xff).b, :bin8, ("\xc4\xff" + "a" * 0xff).b],
      'bin16 blank'  => [0, ''.b, :bin16, "\xc5\x00\x00".b],
      'bin16 a char' => [1, 'a'.b, :bin16, ("\xc5\x00\x01" + "a").b],
      'bin32 blank'  => [0, ''.b, :bin32, "\xc6\x00\x00\x00\x00".b],
      'bin32 a char' => [1, 'a'.b, :bin32, ("\xc6\x00\x00\x00\x01" + "a").b],
    )
    test 'bin' do |results|
      length, string, fmt, str = results
      data = str2data(str)
      assert_equal 1, data.size
      assert_equal fmt, data[0].format
      assert_equal length, data[0].length
      assert_equal string, data[0].value
      assert_equal 'ASCII-8BIT', data[0].value.encoding.name
    end

    data(
      'str16' => [:str16, "\xda\xff\xff".b, 0xffff, "a" * 0xff, 'UTF-8'],
      # it's too heavy...
      # 'str32' => [:str32, "\xdb\xff\xff\xff\xff".b, 0xffffffff, 'UTF-8'],
      # https://gist.github.com/nurse/f9a068c2e84f9324f7626795b212302e
      'str32' => [:str32, "\xdb\x00\x10\x00\x00".b, 0x00100000, "a" * 0x0100, 'UTF-8'],
      'bin16' => [:bin16, "\xc5\xff\xff".b, 0xffff, " " * 0xff, 'ASCII-8BIT'],
      'bin32' => [:bin32, "\xc6\x00\x10\x00\x00".b, 0x00100000, " " * 0x0100, 'ASCII-8BIT'],
    )
    test 'str/bin long data' do |results|
      fmt, header, length, leaf, encoding = results
      io = Tempfile.new("msgpack-inspect-test-")
      io.write header
      (length / leaf.bytesize).times{ io.write leaf }
      io.rewind

      data = io2data(io)
      assert_equal 1, data.size
      assert_equal fmt, data[0].format
      assert_equal length, data[0].length
      assert_equal length, data[0].value.bytesize
      assert_equal encoding, data[0].value.encoding.name
    end

    data(
      'fixarray blank' => [0, :fixarray, "\x90".b],
      'fixarray a element' => [1, :fixarray, "\x91\xc0".b],
      'fixarray 15 elements' => [15, :fixarray, "\x9f\xc0\xc0\xc0\xc0\xc0\xc0\xc0\xc0\xc0\xc0\xc0\xc0\xc0\xc0\xc0".b],
      'array16 blank' => [0, :array16, "\xdc\x00\x00".b],
      'array16 a element' => [1, :array16, "\xdc\x00\x01\xc0".b],
      'array16 max length' => [0xffff, :array16, ("\xdc\xff\xff" + "\xc0" * 0xffff).b],
      'array32 blank' => [0, :array32, "\xdd\x00\x00\x00\x00".b],
      'array32 a element' => [1, :array32, "\xdd\x00\x00\x00\x01\xc0".b],
      'array32 elements' => [0x0001ffff, :array32, ("\xdd\x00\x01\xff\xff" + "\xc0" * 0x0001ffff).b],
    )
    test 'array' do |results|
      length, fmt, str = results
      data = str2data(str)

      assert_equal 1, data.size
      assert_equal fmt, data[0].format
      assert_equal length, data[0].length
      assert_equal length, data[0].children.size
    end

    data(
      'fixmap blank' => [0, :fixmap, "\x80".b],
      'fixmap a element' => [1, :fixmap, "\x81\xc0\xc0".b],
      'fixmap 15 elements' => [15, :fixmap, ("\x8f" + "\xc0\xc0" * 15).b],
      'map16 blank' => [0, :map16, "\xde\x00\x00".b],
      'map16 a element' => [1, :map16, "\xde\x00\x01\xc0\xc0".b],
      'map16 max length' => [0xffff, :map16, ("\xde\xff\xff" + "\xc0\xc0" * 0xffff).b],
      'map32 blank' => [0, :map32, "\xdf\x00\x00\x00\x00".b],
      'map32 a element' => [1, :map32, "\xdf\x00\x00\x00\x01\xc0\xc0".b],
      'map32 elements' => [0x0001ffff, :map32, ("\xdf\x00\x01\xff\xff" + "\xc0\xc0" * 0x0001ffff).b],
    )
    test 'map' do |results|
      length, fmt, str = results
      data = str2data(str)

      assert_equal 1, data.size
      assert_equal fmt, data[0].format
      assert_equal length, data[0].length
      assert_equal length, data[0].children.size
    end

    # data(
    #   'array32 max length' => [0xffffffff, :array32, ("\xdd\xff\xff\xff\xff" + "\xc0" * 0xffffffff).b],
    #   'map32 max length'
    # )
    test 'array/map long data'

    test 'ext'
  end
end
