require 'helper'
require 'msgpack/inspect/inspector'

class MessagePackInspectorTest < ::Test::Unit::TestCase
  sub_test_case 'msgpack' do
    test 'true, false, nil, never_used' do
      str = [
        MessagePack.pack(true),
        MessagePack.pack(true),
        MessagePack.pack(false),
        MessagePack.pack(nil),
        "\xc1".b,
      ].join
      src = StringIO.new(str)
      ins = MessagePack::Inspect::Inspector.new(src)
      assert_equal :true, ins.data[0][:format]
      assert_equal true, ins.data[0][:value]
      assert_equal :true, ins.data[1][:format]
      assert_equal true, ins.data[1][:value]
      assert_equal :false, ins.data[2][:format]
      assert_equal false, ins.data[2][:value]
      assert_equal :nil, ins.data[3][:format]
      assert_equal nil, ins.data[3][:value]
      assert_equal :never_used, ins.data[4][:format]
      assert_equal "msgpack format 'NEVER USED' specified", ins.data[4][:error]
    end

    test 'str' do
      str = ["Hello", "こんにちは"].map{|s| MessagePack.pack(s) }.join
      src = StringIO.new(str)
      ins = MessagePack::Inspect::Inspector.new(src)
      assert_equal :fixstr, ins.data[0][:format]
      assert_equal "Hello", ins.data[0][:value]
      assert_equal :fixstr, ins.data[1][:format]
      assert_equal "こんにちは", ins.data[1][:value]
    end
  end
end
