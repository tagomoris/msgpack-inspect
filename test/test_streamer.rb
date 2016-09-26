require 'helper'
require 'yaml'
require 'json'
require 'stringio'

class MessagePackInspectStreamerTest < ::Test::Unit::TestCase
  def node2hash(node)
    case node.format
    when :nil
      {"format" => "nil", "header" => "0x#{node.hex(node.header)}", "data" => "0x#{node.data}", "value" => nil}
    when :false
      {"format" => "false", "header" => "0x#{node.hex(node.header)}", "data" => "0x#{node.data}", "value" => false}
    when :true
      {"format" => "true", "header" => "0x#{node.hex(node.header)}", "data" => "0x#{node.data}", "value" => true}
    when :never_used
      {"format" => "never_used", "header" => "0x{node.hex(node.header)}", "error" => "msgpack format 'NEVER USED' specified"}
    when :fixint, :uint8, :uint16, :uint32, :uint64, :int8, :int16, :int32, :int64, :float32, :float64
      {"format" => "#{node.format.to_s}", "header" => "0x#{node.hex(node.header)}", "data" => "0x#{node.data}", "value" => node.value}
    when :fixstr, :str8, :str16, :str32, :bin8, :bin16, :bin32
      {"format" => "#{node.format.to_s}", "header" => "0x#{node.hex(node.header)}", "length" => node.length, "data" => "0x#{node.data}", "value" => node.value}
    when :ext8, :ext16, :ext32, :fixext1, :fixext2, :fixext4, :fixext8, :fixext16
      # ext not registered
      {"format" => "#{node.format.to_s}", "header" => "0x#{node.hex(node.header)}", "exttype" => node.exttype, "length" => node.length, "data" => "0x#{node.data}"}
    when :fixmap, :map16, :map32
      {"format" => "#{node.format.to_s}", "header" => "0x#{node.hex(node.header)}", "length" => node.length, "children" => node.children.map{|kvs| kvs.map{|k,v| {"key" => node2hash(k), "value" => node2hash(v)} } }.flatten}
    when :fixarray, :array16, :array32
      {"format" => "#{node.format.to_s}", "header" => "0x#{node.hex(node.header)}", "length" => node.length, "children" => node.children.map{|e| node2hash(e) } }
    end
  end

  setup do
    @msgpack_bin = File.open(File.expand_path("../../msgpack-example.bin", __FILE__)){|f| f.read }
    @expected = str2data(@msgpack_bin).map{|n| node2hash(n) }
  end

  sub_test_case 'yaml' do
    test 'outputs valid YAML data' do
      output = StringIO.new
      MessagePack::Inspect::Inspector.new(StringIO.new(@msgpack_bin), :yaml, output_io: output).inspect
      assert_equal @expected, YAML.load(output.string)
    end
  end

  sub_test_case 'json' do
    test 'outputs valid JSON data' do
      output = StringIO.new
      MessagePack::Inspect::Inspector.new(StringIO.new(@msgpack_bin), :json, output_io: output).inspect
      assert_equal @expected, JSON.load(output.string)
    end
  end

  sub_test_case 'jsonl' do
    test 'outputs valid JSONL data per line' do
      output = StringIO.new
      MessagePack::Inspect::Inspector.new(StringIO.new(@msgpack_bin), :jsonl, output_io: output).inspect
      @data = []
      output.string.each_line do |line|
        @data << JSON.load(line)
      end
      assert_equal @expected, @data
    end
  end

  sub_test_case 'all formats' do
    test 'generates exact same data' do
      o1 = StringIO.new
      MessagePack::Inspect::Inspector.new(StringIO.new(@msgpack_bin), :yaml, output_io: o1).inspect
      from_yaml = YAML.load(o1.string)

      o2 = StringIO.new
      MessagePack::Inspect::Inspector.new(StringIO.new(@msgpack_bin), :json, output_io: o2).inspect
      from_json = JSON.load(o2.string)

      o3 = StringIO.new
      MessagePack::Inspect::Inspector.new(StringIO.new(@msgpack_bin), :jsonl, output_io: o3).inspect
      from_jsonl = []
      o3.string.each_line do |line|
        from_jsonl << JSON.load(line)
      end

      assert_equal from_yaml, from_json
      assert_equal from_json, from_jsonl
      assert_equal from_jsonl, from_yaml
    end
  end
end
